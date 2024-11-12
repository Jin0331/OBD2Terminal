//
//  OBD2Service.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/7/24.
//

import SwiftUI
import Combine
import CoreBluetooth
import Foundation
import ComposableArchitecture

final class OBDService : ObservableObject {
    static let shared = OBDService()
    @Shared(Environment.SharedInMemoryType.obdLog.keys) var obdLog : [String] = .init()
    @Published public  var connectionType: ConnectionType = .bluetooth
    @Published var btList: BluetoothItemList = .init()
    
    var pidList: [OBDCommand] = []
    
    private var elm327: ELM327
    private var bleManager : BLEManager
    private var cancellables = Set<AnyCancellable>()
    
    /// Sending Data
    let onDeviceFoundProperty: PassthroughSubject<BluetoothDeviceList, Never> = .init()
    let onDeviceErrorProperty : PassthroughSubject<Void, Never> = .init()
    let onConnectDeviceProperty: PassthroughSubject<BluetoothDevice, Never>  = .init()
    let onConnectEcuProperty : PassthroughSubject<Void, Never> = .init()
    let onConnectFailedDeviceProperty: PassthroughSubject<BluetoothDevice, Never>  = .init()
    let onDisConnectDeviceProperty: PassthroughSubject<BluetoothDevice, Never>  = .init()
    
    init(connectionType: ConnectionType = .bluetooth) {
        self.connectionType = connectionType
        switch connectionType {
        case .bluetooth:
            bleManager = BLEManager()
            elm327 = ELM327(comm: bleManager)
            /*
             case .wifi:
             wifi mode 지원시 추가
             */
        }
            
        /// EventDelegate 소유
        bleManager.obdScanDelegate = self
        
        bleManager.obdConnectionDelegate = self
        elm327.obdConnectionDelegate = self
    }
    
    /// Initiates the connection process to the OBD2 adapter and vehicle.
    ///
    /// - Parameter preferedProtocol: The optional OBD2 protocol to use (if supported).
    /// - Returns: Information about the connected vehicle (`OBDInfo`).
    /// - Throws: Errors that might occur during the connection process.
    func startConnection(address : String?, preferedProtocol: PROTOCOL? = nil, timeout: TimeInterval = 7) async throws -> OBDInfo {
        
        guard let address else {
            throw OBDServiceError.noAdapterFound
        }
        
        do {
            try await elm327.connectToAdapter(timeout: timeout, address: address)
            try await elm327.adapterInitialization()
            let obdInfo = try await initializeVehicle(preferedProtocol)
            
            Logger.debug("ECU Connected 🌱")
            
            return obdInfo
        } catch {
            Logger.error(error)
            throw OBDServiceError.adapterConnectionFailed(underlyingError: error) // Propagate
        }
    }
    
    /// Initializes communication with the vehicle and retrieves vehicle information.
    ///
    /// - Parameter preferedProtocol: The optional OBD2 protocol to use (if supported).
    /// - Returns: Information about the connected vehicle (`OBDInfo`).
    /// - Throws: Errors if the vehicle initialization process fails.
    func initializeVehicle(_ preferedProtocol: PROTOCOL?) async throws -> OBDInfo {
        do {
            let obd2info = try await elm327.setupVehicle(preferredProtocol: preferedProtocol)
            onConnectEcuProperty.send(())
            return obd2info
        } catch {
            Logger.error(error)
            onDeviceErrorProperty.send(())
            throw OBDServiceError.initializeVehicle(underlyingError: error)
        }
    }
    
    /// Terminates the connection with the OBD2 adapter.
    func stopConnection() {
        elm327.stopConnection()
    }
    
    /// Switches the active connection type (between Bluetooth and Wi-Fi).
    ///
    /// - Parameter connectionType: The new desired connection type.
    func switchConnectionType(_ connectionType: ConnectionType) {
        self.stopConnection()
        switch connectionType {
        case .bluetooth:
            elm327 = ELM327(comm: BLEManager())
        }
    }
    
    /// Sends an OBD2 command to the vehicle and returns a publisher with the result.
    /// - Parameter command: The OBD2 command to send.
    /// - Returns: A publisher with the measurement result.
    /// - Throws: Errors that might occur during the request process.
    func startContinuousUpdates(_ pids: [OBDCommand], unit: MeasurementUnit = .metric, interval: TimeInterval = 0.3) -> AnyPublisher<[OBDCommand: MeasurementResult], Error> {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .flatMap { [weak self] _ -> Future<[OBDCommand: MeasurementResult], Error> in
                Future { promise in
                    guard let self = self else {
                        promise(.failure(OBDServiceError.notConnectedToVehicle))
                        return
                    }
                    Task(priority: .userInitiated) {
                        do {
                            let results = try await self.requestPIDs(pids, unit: unit)
                            promise(.success(results))
                        } catch {
                            Logger.error(error)
                            promise(.failure(error))
                        }
                    }
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Adds an OBD2 command to the list of commands to be requested.
    func addPID(_ pid: OBDCommand) {
        pidList.append(pid)
    }
    
    /// Removes an OBD2 command from the list of commands to be requested.
    func removePID(_ pid: OBDCommand) {
        pidList.removeAll { $0 == pid }
    }
    
    /// Sends an OBD2 command to the vehicle and returns the raw response.
    /// - Parameter command: The OBD2 command to send.
    /// - Returns: measurement result
    /// - Throws: Errors that might occur during the request process.
    @discardableResult
    func requestPIDs(_ commands: [OBDCommand], unit: MeasurementUnit) async throws -> [OBDCommand: MeasurementResult] {
        let response = try await sendCommandInternal(commands.compactMap { $0.properties.command }.joined(), retries: 10)
        
        Logger.debug("requestPIDs Response: \(response)")
        
        guard let responseData = try elm327.canProtocol?.parse(response).first?.data else { return [:] }
        
        var batchedResponse = BatchedResponse(response: responseData, unit)
        
        let results: [OBDCommand: MeasurementResult] = commands.reduce(into: [:]) { result, command in
            let measurement = batchedResponse.extractValue(command)
            result[command] = measurement
        }
        
        return results
    }
    
    /// Sends an OBD2 command to the vehicle and returns the raw response.
    ///  - Parameter command: The OBD2 command to send.
    ///  - Returns: The raw response from the vehicle.
    ///  - Throws: Errors that might occur during the request process.
    func sendCommand(_ command: OBDCommand) async throws -> Result<DecodeResult, DecodeError> {
        do {
            let response = try await sendCommandInternal(command.properties.command, retries: 3)
            guard let responseData = try elm327.canProtocol?.parse(response).first?.data else {
                return .failure(.noData)
            }
            return command.properties.decode(data: responseData.dropFirst())
        } catch {
            Logger.error(error)
            throw OBDServiceError.commandFailed(command: command.properties.command, error: error)
        }
    }
    
    /// Sends an OBD2 command to the vehicle and returns the raw response.
    ///   - Parameter command: The OBD2 command to send.
    ///   - Returns: The raw response from the vehicle.
    func getSupportedPIDs() async -> [OBDCommand] {
        return await elm327.getSupportedPIDs()
    }
    
    ///  Scans for trouble codes and returns the result.
    ///  - Returns: The trouble codes found on the vehicle.
    ///  - Throws: Errors that might occur during the request process.
    func scanForTroubleCodes() async throws -> [ECUID:[TroubleCode]] {
        do {
            return try await elm327.scanForTroubleCodes()
        } catch {
            Logger.error(error)
            throw OBDServiceError.scanFailed(underlyingError: error)
        }
    }
    
    /// Clears the trouble codes found on the vehicle.
    ///  - Throws: Errors that might occur during the request process.
    ///     - `OBDServiceError.notConnectedToVehicle` if the adapter is not connected to a vehicle.
    func clearTroubleCodes() async throws {
        do {
            try await elm327.clearTroubleCodes()
        } catch {
            Logger.error(error)
            throw OBDServiceError.clearFailed(underlyingError: error)
        }
    }
    
    /// Returns the vehicle's status.
    ///  - Returns: The vehicle's status.
    ///  - Throws: Errors that might occur during the request process.
    func getStatus() async throws -> Result<DecodeResult, DecodeError> {
        do {
            return try await elm327.getStatus()
        } catch {
            Logger.error(error)
            throw error
        }
    }
    
    /// Sends a raw command to the vehicle and returns the raw response.
    /// - Parameter message: The raw command to send.
    /// - Returns: The raw response from the vehicle.
    /// - Throws: Errors that might occur during the request process.
    func sendCommandInternal(_ message: String, retries: Int) async throws -> [String] {
        do {
            return try await elm327.sendCommand(message, retries: retries)
        } catch {
            Logger.error(error)
            throw OBDServiceError.commandFailed(command: message, error: error)
        }
    }
    
    func connectToPeripheral(address: String) async throws {
        do {
            try await elm327.connectToAdapter(timeout: 60,address: address)
        } catch {
            Logger.error(error)
            throw OBDServiceError.adapterConnectionFailed(underlyingError: error)
        }
    }
    
    func startScan() async throws {
        bleManager.startScanning()
    }
    
    func stopScan() async throws {
        bleManager.stopScanning()
    }
    
    func getVINInfo(vin: String) async throws -> VINResults {
        let endpoint = "https://vpic.nhtsa.dot.gov/api/vehicles/decodevinvalues/\(vin)?format=json"
        
        guard let url = URL(string: endpoint) else {
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(VINResults.self, from: data)
        return decoded
    }
}

//MARK: - BluetoothScanEventDelegate
extension OBDService :BluetoothScanEventDelegate {
    func onDiscoveryStarted() {
        
    }
    
    func onDiscoveryFinised() {
        
    }
    
    func onDeviceFound(device: BluetoothDeviceList) {
        Logger.debug("Found device: \(device)")
        addBTList(device)
        onDeviceFoundProperty.send(device)
    }
}

//MARK: - BluetoothConnectionDelegate
extension OBDService : BluetoothConnectionEventDelegate {
    func onConnectingEcu() {
        
    }
    
    func onConnectEcu() {
        
    }
    
    func onConnectingDevice(device: BluetoothDevice) {
        Logger.info("onConnectingDevice \(device)")
    }
    
    func onConnectDevice(device: BluetoothDevice) {
        Logger.info("onConnectDevice \(device)")
        onConnectDeviceProperty.send(device)
    }
    
    func onConnectFailedDevice(device: BluetoothDevice) {
        Logger.error("onConnectFailedDevice \(device)")
        onConnectFailedDeviceProperty.send(device)
    }
    
    func onDisConnectDevice(device: BluetoothDevice) {
        Logger.info("onConnectDevice \(device)")
        onDisConnectDeviceProperty.send(device)
    }
    
    func onOBDLog(logs: String) {
        obdLog.append(logs)
        Logger.debug("obdLog: \(obdLog)")
    }
}

extension OBDService {
    /// Adding Bluetooth Device
    func addBTList(_ addList : BluetoothDeviceList) {
        btList = addList.map { BluetoothItem(name: $0.name, address: $0.address, rssi: $0.rssi) }
    }
    
    /// Removing Bluetooth Device
    func delBTList(at indexPath: IndexPath) {
        btList.remove(at: indexPath.row)
    }
}

private enum OBDServiceKey : DependencyKey {
    static var liveValue: OBDService = OBDService()
}

extension DependencyValues {
    var obdService : OBDService {
        get { self[OBDServiceKey.self] }
        set { self[OBDServiceKey.self] = newValue}
    }
}
