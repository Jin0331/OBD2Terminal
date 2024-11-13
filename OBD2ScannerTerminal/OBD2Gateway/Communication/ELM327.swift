//
//  ELM327.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/7/24.
//

import Combine
import Foundation
import CoreBluetooth

final class ELM327 {
    var canProtocol: CANProtocol?
    var obdConnectionDelegate: BluetoothConnectionEventDelegate?
    private var comm: CommProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private var r100: [String] = []
    
    init(comm: CommProtocol) {
        self.comm = comm
    }
    
    
    // MARK: - Adapter and Vehicle Setup
    /// Sets up the vehicle connection, including automatic protocol detection.
    /// - Parameter preferedProtocol: An optional preferred protocol to attempt first.
    /// - Returns: A tuple containing the established OBD protocol and the vehicle's VIN (if available).
    /// - Throws:
    ///     - `SetupError.noECUCharacteristic` if the required OBD characteristic is not found.
    ///     - `SetupError.invalidResponse(message: String)` if the adapter's response is unexpected.
    ///     - `SetupError.noProtocolFound` if no compatible protocol can be established.
    ///     - `SetupError.adapterInitFailed` if initialization of adapter failed.
    ///     - `SetupError.timeout` if a response times out.
    ///     - `SetupError.peripheralNotFound` if the peripheral could not be found.
    ///     - `SetupError.ignitionOff` if the vehicle's ignition is not on.
    ///     - `SetupError.invalidProtocol` if the protocol is not recognized.
    func setupVehicle(preferredProtocol: PROTOCOL?) async throws -> OBDInfo {
        //        var obdProtocol: PROTOCOL?
        let detectedProtocol = try await detectProtocol(preferredProtocol: preferredProtocol)
        
        //        guard let obdProtocol = detectedProtocol else {
        //            throw SetupError.noProtocolFound
        //        }
        
        //        self.obdProtocol = obdProtocol
        self.canProtocol = protocols[detectedProtocol]
        
        let vin = await requestVin()
        
        //        try await setHeader(header: "7E0")
        
        let supportedPIDs = await getSupportedPIDs()
        
        guard let messages = try canProtocol?.parse(r100) else {
            obdConnectionDelegate?.onOBDLog(logs: "Invalid response to 0100")
            throw ELM327Error.invalidResponse(message: "Invalid response to 0100")
        }
        
        let ecuMap = populateECUMap(messages)
        
        return OBDInfo(vin: vin, supportedPIDs: supportedPIDs, obdProtocol: detectedProtocol, ecuMap: ecuMap)
    }
    
    // MARK: - Protocol Selection
    
    /// Detects the appropriate OBD protocol by attempting preferred and fallback protocols.
    /// - Parameter preferredProtocol: An optional preferred protocol to attempt first.
    /// - Returns: The detected `PROTOCOL`.
    /// - Throws: `ELM327Error` if detection fails.
    private func detectProtocol(preferredProtocol: PROTOCOL? = nil) async throws -> PROTOCOL {
        Logger.info("Starting protocol detection...")
        obdConnectionDelegate?.onOBDLog(logs: "Starting protocol detection...")
        
        if let protocolToTest = preferredProtocol {
            Logger.info("Attempting preferred protocol: \(protocolToTest.description)")
            obdConnectionDelegate?.onOBDLog(logs: "Attempting preferred protocol: \(protocolToTest.description)")
            if try await testProtocol(protocolToTest) {
                return protocolToTest
            } else {
                Logger.warning("Preferred protocol \(protocolToTest.description) failed. Falling back to automatic detection.")
                obdConnectionDelegate?.onOBDLog(logs: "Preferred protocol \(protocolToTest.description) failed. Falling back to automatic detection.")
            }
        } else {
            do {
                return try await detectProtocolAutomatically()
            } catch {
                return try await detectProtocolManually()
            }
        }
        
        Logger.error("Failed to detect a compatible OBD protocol.")
        obdConnectionDelegate?.onOBDLog(logs: "Failed to detect a compatible OBD protocol.")
        throw ELM327Error.noProtocolFound
    }
    
    /// Attempts to detect the OBD protocol automatically.
    /// - Returns: The detected protocol, or nil if none could be found.
    /// - Throws: Various setup-related errors.
    private func detectProtocolAutomatically() async throws -> PROTOCOL {
        Logger.info("detectProtocolAutomatically")
        try await okResponse("ATSP0")
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        try await sendCommand("0100")
        
        let obdProtocolNumber = try await sendCommand("ATDPN")
        
        guard let obdProtocol = PROTOCOL(rawValue: String(obdProtocolNumber[0].dropFirst())) else {
            obdConnectionDelegate?.onOBDLog(logs: "Invalid protocol number: \(obdProtocolNumber)")
            throw ELM327Error.invalidResponse(message: "Invalid protocol number: \(obdProtocolNumber)")
        }
        
        try await testProtocol(obdProtocol)
        
        return obdProtocol
    }
    
    /// Attempts to detect the OBD protocol manually.
    /// - Parameter desiredProtocol: An optional preferred protocol to attempt first.
    /// - Returns: The detected protocol, or nil if none could be found.
    /// - Throws: Various setup-related errors.
    private func detectProtocolManually() async throws -> PROTOCOL {
        for protocolOption in PROTOCOL.allCases where protocolOption != .NONE {
            Logger.info("Testing protocol: \(protocolOption.description)")
            _ = try await okResponse(protocolOption.cmd)
            if try await testProtocol(protocolOption) {
                return protocolOption
            }
        }
        /// If we reach this point, no protocol was found
        Logger.error("No protocol found")
        obdConnectionDelegate?.onOBDLog(logs: "No protocol found")
        throw ELM327Error.noProtocolFound
    }
    
    /// Tests a given protocol by sending a 0100 command and checking for a valid response.
    /// - Parameter obdProtocol: The protocol to test.
    /// - Throws: Various setup-related errors.
    @discardableResult
    private func testProtocol(_ obdProtocol: PROTOCOL) async throws -> Bool {
        // test protocol by sending 0100 and checking for 41 00 response
        do {
            let response = try await sendCommand("0100", retries: 3)
            
            if response.joined().contains("4100") {
                obdConnectionDelegate?.onOBDLog(logs: "Protocol \(obdProtocol.description) is valid.")
                Logger.info("Protocol \(obdProtocol.description) is valid.")
                self.r100 = response
                return true
            } else {
                obdConnectionDelegate?.onOBDLog(logs: "Protocol \(obdProtocol.rawValue) did not return valid 0100 response.")
                Logger.warning("Protocol \(obdProtocol.rawValue) did not return valid 0100 response.")
                return false
            }
        } catch {
            obdConnectionDelegate?.onOBDLog(logs: "Error testing protocol \(obdProtocol.description): \(error.localizedDescription)")
            Logger.warning("Error testing protocol \(obdProtocol.description): \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Adapter Initialization
    func connectToAdapter(timeout: TimeInterval, address: String? = nil) async throws {
        try await comm.connectAsync(timeout: timeout, address: address)
    }
    
    /// Initializes the adapter by sending a series of commands.
    /// - Parameter setupOrder: A list of commands to send in order.
    /// - Throws: Various setup-related errors.
    func adapterInitialization() async throws {
        /// [.ATZ, .ATD, .ATL0, .ATE0, .ATH1, .ATAT1, .ATRV, .ATDPN]
        Logger.info("Initializing ELM327 adapter...")
        obdConnectionDelegate?.onOBDLog(logs: "Initializing ELM327 adapter...")
        do {
            try await sendCommand("ATZ") // Reset adapter
            try await okResponse("ATE0") // Echo off
            try await okResponse("ATS0") // Spaces off
            try await okResponse("ATL0") // Linefeeds off
            try await okResponse("ATH1") // Headers off
            try await okResponse("ATSP0") // Set protocol to automatic
            Logger.info("ELM327 adapter initialized successfully.")
            obdConnectionDelegate?.onOBDLog(logs: "ELM327 adapter initialized successfully.")
        } catch {
            Logger.error("Adapter initialization failed: \(error.localizedDescription)")
            obdConnectionDelegate?.onOBDLog(logs:"\(ELM327Error.adapterInitializationFailed)")
            throw ELM327Error.adapterInitializationFailed
        }
    }
    
    private func setHeader(header: String) async throws {
        try await okResponse("AT SH " + header)
    }
    
    func stopConnection() {
        comm.disconnectPeripheral()
    }
    
    // MARK: - Message Sending
    @discardableResult
    func sendCommand(_ message: String, retries: Int = 1) async throws -> [String] {
        return try await comm.sendCommand(message, retries: retries)
    }
    
    @discardableResult
    func okResponse(_ message: String, _ initMode : Bool = true) async throws -> [String] {
        let response = try await sendCommand(message)
        if response.contains("OK") {
//            if !initMode {
//                obdConnectionDelegate?.onOBDLog(logs: "Parse Response: \(response)")
//            }
            return response
        } else {
            Logger.error("Invalid response: \(response)")
            throw ELM327Error.invalidResponse(message: "message: \(message), \(String(describing: response.first))")
        }
    }
    
    func getStatus() async throws -> Result<DecodeResult, DecodeError> {
        Logger.info("Getting status")
        let statusCommand = OBDCommand.Mode1.status
        let statusResponse = try await sendCommand(statusCommand.properties.command)
        Logger.debug("Status response: \(statusResponse)")
        guard let statusData = try canProtocol?.parse(statusResponse).first?.data else {
            return .failure(.noData)
        }
        return statusCommand.properties.decode(data: statusData)
    }
    
    func scanForTroubleCodes() async throws -> [ECUID:[TroubleCode]] {
        var dtcs: [ECUID:[TroubleCode]]  = [:]
        Logger.info("Scanning for trouble codes")
        let dtcCommand = OBDCommand.Mode3.GET_DTC
        let dtcResponse = try await sendCommand(dtcCommand.properties.command)
        
        guard let messages = try canProtocol?.parse(dtcResponse) else {
            return [:]
        }
        for message in messages {
            guard let dtcData = message.data else {
                continue
            }
            let decodedResult = dtcCommand.properties.decode(data: dtcData)
            
            let ecuId = message.ecu
            switch decodedResult {
            case .success(let result):
                dtcs[ecuId] = result.troubleCode
                
            case .failure(let error):
                Logger.error("Failed to decode DTC: \(error)")
            }
        }
        
        return dtcs
    }
    
    func clearTroubleCodes() async throws {
        let command = OBDCommand.Mode4.CLEAR_DTC
        try await sendCommand(command.properties.command)
    }
    
    func scanForPeripherals() async throws {
        try await comm.scanForPeripherals()
    }
    
    func requestVin() async -> String? {
        let command = OBDCommand.Mode9.VIN
        guard let vinResponse = try? await sendCommand(command.properties.command) else {
            return nil
        }
        
        
        guard let data = try? canProtocol?.parse(vinResponse).first?.data,
              var vinString = String(bytes: data, encoding: .utf8)
        else {
            return nil
        }
        
        vinString = vinString
            .replacingOccurrences(of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
        
        return vinString
    }
}

extension ELM327 {
    private func populateECUMap(_ messages: [MessageProtocol]) -> [UInt8: ECUID]? {
        let engineTXID = 0
        let transmissionTXID = 1
        var ecuMap: [UInt8: ECUID] = [:]
        
        // If there are no messages, return an empty map
        guard !messages.isEmpty else {
            return nil
        }
        
        // If there is only one message, assume it's from the engine
        if messages.count == 1 {
            ecuMap[messages.first?.ecu.rawValue ?? 0] = .engine
            return ecuMap
        }
        
        // Find the engine and transmission ECU based on TXID
        var foundEngine = false
        
        for message in messages {
            let txID = message.ecu.rawValue
            
            if txID == engineTXID {
                ecuMap[txID] = .engine
                foundEngine = true
            } else if txID == transmissionTXID {
                ecuMap[txID] = .transmission
            }
        }
        
        // If engine ECU is not found, choose the one with the most bits
        if !foundEngine {
            var bestBits = 0
            var bestTXID: UInt8?
            
            for message in messages {
                guard let bits = message.data?.bitCount() else {
                    Logger.error("parse_frame failed to extract data")
                    continue
                }
                if bits > bestBits {
                    bestBits = bits
                    bestTXID = message.ecu.rawValue
                }
            }
            
            if let bestTXID = bestTXID {
                ecuMap[bestTXID] = .engine
            }
        }
        
        // Assign transmission ECU to messages without an ECU assignment
        for message in messages where ecuMap[message.ecu.rawValue] == nil {
            ecuMap[message.ecu.rawValue] = .transmission
        }
        
        return ecuMap
    }
    
    func getSupportedPIDs() async -> [OBDCommand] {
        let pidGetters = OBDCommand.pidGetters
        var supportedPIDs: [OBDCommand] = []
        
        for pidGetter in pidGetters {
            do {
                Logger.info("Getting supported PIDs for \(pidGetter.properties.command)")
                let response = try await sendCommand(pidGetter.properties.command)
                // find first instance of 41 plus command sent, from there we determine the position of everything else
                // Ex.
                //        || ||
                // 7E8 06 41 00 BE 7F B8 13
                guard let supportedPidsByECU = try? parseResponse(response) else {
                    continue
                }
                
                let supportedCommands = OBDCommand.allCommands
                    .filter { supportedPidsByECU.contains(String($0.properties.command.dropFirst(2))) }
                    .map { $0 }
                
                supportedPIDs.append(contentsOf: supportedCommands)
            } catch {
                Logger.error("\(error.localizedDescription)")
            }
        }
        // filter out pidGetters
        supportedPIDs = supportedPIDs.filter { !pidGetters.contains($0) }
        
        // remove duplicates
        return Array(Set(supportedPIDs))
    }
    
    private func parseResponse(_ response: [String]) throws -> Set<String>? {
        guard let ecuData = try? canProtocol?.parse(response).first?.data else {
            return nil
        }
        let binaryData = BitArray(data: ecuData.dropFirst()).binaryArray
        return extractSupportedPIDs(binaryData)
    }
    
    func extractSupportedPIDs(_ binaryData: [Int]) -> Set<String> {
        var supportedPIDs: Set<String> = []
        
        for (index, value) in binaryData.enumerated() {
            if value == 1 {
                let pid = String(format: "%02X", index + 1)
                supportedPIDs.insert(pid)
            }
        }
        return supportedPIDs
    }
}
