//
//  BLEManager.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/7/24.
//

import Combine
import CoreBluetooth
import Foundation

final class BLEManager: NSObject, CommProtocol {
    
    static let shared = BLEManager()
    
    private let peripheralSubject = PassthroughSubject<CBPeripheral, Never>()
    
    var peripheralPublisher: AnyPublisher<CBPeripheral, Never> {
        return peripheralSubject.eraseToAnyPublisher()
    }
    
    static let services = [
        CBUUID(string: "FFE0"),
        CBUUID(string: "FFF0"),
        CBUUID(string: "18F0") //e.g. VGate iCar Pro
    ]
    
    static let RestoreIdentifierKey: String = "OBD2Adapter"
    
    @Published var connectedPeripheral: CBPeripheral?
    var deviceListWithPublished = [BluetoothDevice]()
    
    private var centralManager: CBCentralManager!
    private var ecuReadCharacteristic: CBCharacteristic?
    private var ecuWriteCharacteristic: CBCharacteristic?
    private var deviceList = [String: CBPeripheral]()
    private var buffer = Data()
    
    private var sendMessageCompletion: (([String]?, Error?) -> Void)?
    private var foundPeripheralCompletion: ((CBPeripheral?, Error?) -> Void)?
    private var connectionCompletion: ((CBPeripheral?, Error?) -> Void)?
    
    var obdScanDelegate: BluetoothScanEventDelegate?
    var obdConnectionDelegate: BluetoothConnectionEventDelegate?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .global(qos: .userInteractive))
    }
    
    /// Bluetooth Connect 관련
    func startScanning(_ serviceUUIDs: [CBUUID]? = BLEManager.services) {
        guard centralManager.state == .poweredOn else { return }
        
        // 스캔중이면 스캔종료 후 스캔시작
        if centralManager.isScanning {
            obdScanDelegate?.onDiscoveryFinised()
        }
        
        deviceList.removeAll()
        deviceListWithPublished.removeAll()
        
        /// Scan for Bluetooth Device
        centralManager?.scanForPeripherals(withServices: serviceUUIDs, options: nil)
        
        obdScanDelegate?.onDiscoveryStarted()
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    func disconnectPeripheral() {
        guard let connectedPeripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(connectedPeripheral)
    }
    
    func didUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            Logger.info(">>> Bluetooth is powered on.")
        case .poweredOff:
            Logger.warning("Bluetooth is currently powered off.")
            connectedPeripheral = nil
        case .unsupported:
            Logger.error("This device does not support Bluetooth Low Energy.")
        case .unauthorized:
            Logger.error("This app is not authorized to use Bluetooth Low Energy.")
        case .resetting:
            Logger.warning("Bluetooth is resetting.")
        default:
            Logger.error("Bluetooth is not powered on.")
            fatalError()
        }
    }
    
    func didDiscover(_: CBCentralManager, peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        guard let name = peripheral.name else { return }
        let address = peripheral.identifier.uuidString
        let rssi = rssi.intValue
        
        deviceList[address] = peripheral
        // 기존에 있던 장치 업데이트 또는 새로 추가
        if let index = deviceListWithPublished.firstIndex(where: { $0.address == address }) {
            deviceListWithPublished[index].rssi = rssi
            deviceListWithPublished[index].lastSeen = Date() // 마지막으로 발견된 시간 업데이트
        } else {
            let newDevice = BluetoothDevice(name: name, address: address, rssi: rssi, lastSeen: Date())
            deviceListWithPublished.append(newDevice)
        }
        
        /// 연결가능한 OBD2 발견할 때 마다, 해당 Array update
        if peripheral.state == .disconnected {
            self.connectedPeripheral = peripheral
            self.obdScanDelegate?.onDeviceFound(device: deviceListWithPublished)
        }
        
        removeLostDevices()
    }
    
    func connect(address: String?) {
        guard let address else {
            Logger.error("Blueetooth address is Empty")
            return
        }
        Logger.info("Bluetooth address: \(address)")
        obdConnectionDelegate?.onOBDLog(logs: "Connecting Bluetooth for OBD Address: \(address)")
        if let peripheral = deviceList[address]{
            connect(peripheral)
        } else {
            Logger.error("Bluetooth address is Empty")
        }
    }
    
    /// 파라미터로 넘어온 주변 기기를 CentralManager에 연결하도록 시도합니다.
    private func connect(_ peripheral: CBPeripheral){
        let name    = peripheral.name
        let address = peripheral.identifier.uuidString
        let device = BluetoothDevice(name: name!, address: address, rssi: 0, lastSeen: Date())
        
        
        // 주변 기기와 연결 실패 시 동작하는 코드를 여기에 작성합니다.
        obdConnectionDelegate?.onConnectingDevice(device: device)
        
        // 연결 실패를 대비하여 현재 연결 중인 주변 기기를 저장합니다.
        centralManager.connect(peripheral, options: nil)
    }
    
    func didConnect(_: CBCentralManager, peripheral: CBPeripheral) {
        Logger.info("Connected to peripheral: \(peripheral.name ?? "Unnamed")")
        connectedPeripheral = peripheral
        connectedPeripheral?.delegate = self
        connectedPeripheral?.discoverServices(Self.services)
        
        obdConnectionDelegate?.onConnectDevice(device: BluetoothDevice(name: peripheral.name ?? "Unnamed", address: peripheral.identifier.uuidString, rssi: 0, lastSeen: Date()))
    }
    
    func scanForPeripheralAsync(_ timeout: TimeInterval) async throws -> CBPeripheral? {
        // returns a single peripheral with the specified services
        return try await Timeout(seconds: timeout) {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<CBPeripheral, Error>) in
                self.foundPeripheralCompletion = { peripheral, error in
                    if let peripheral = peripheral {
                        continuation.resume(returning: peripheral)
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    }
                    self.foundPeripheralCompletion = nil
                }
                self.startScanning(Self.services)
            }
        }
    }
    
    func didDiscoverServices(_ peripheral: CBPeripheral, error _: Error?) {
        for service in peripheral.services ?? [] {
            Logger.info("Discovered service: \(service.uuid.uuidString)")
            switch service {
            case CBUUID(string: "FFE0"):
                peripheral.discoverCharacteristics([CBUUID(string: "FFE1")], for: service)
            case CBUUID(string: "FFF0"):
                peripheral.discoverCharacteristics([CBUUID(string: "FFF1"), CBUUID(string: "FFF2")], for: service)
            case CBUUID(string: "18F0"):
                peripheral.discoverCharacteristics([CBUUID(string: "2AF0"), CBUUID(string: "2AF1")], for: service)
            default:
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func didDiscoverCharacteristics(_ peripheral: CBPeripheral, service: CBService, error _: Error?) {
        guard let characteristics = service.characteristics, !characteristics.isEmpty else {
            return
        }
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
            switch characteristic.uuid.uuidString {
            case "FFE1": // for servcice FFE0
                ecuWriteCharacteristic = characteristic
                ecuReadCharacteristic = characteristic
            case "FFF1": // for servcice FFF0
                ecuReadCharacteristic = characteristic
            case "FFF2": // for servcice FFF0
                ecuWriteCharacteristic = characteristic
            case "2AF0": // for servcice 18F0
                ecuReadCharacteristic = characteristic
            case "2AF1": // for servcice 18F0
                ecuWriteCharacteristic = characteristic
            default:
                break
            }
        }
        
        if connectionCompletion != nil && ecuWriteCharacteristic != nil && ecuReadCharacteristic != nil {
            connectionCompletion?(peripheral, nil)
        }
    }
    
    func didUpdateValue(_: CBPeripheral, characteristic: CBCharacteristic, error: Error?) {
        if let error {
            Logger.error("Error reading characteristic value: \(error.localizedDescription)")
            return
        }
        
        guard let characteristicValue = characteristic.value else {
            return
        }
        
        switch characteristic {
        case ecuReadCharacteristic:
            processReceivedData(characteristicValue, completion: sendMessageCompletion)
        default:
            if let responseString = String(data: characteristicValue, encoding: .utf8) {
                Logger.info("Unknown characteristic: \(characteristic)\nResponse: \(responseString)")
            }
        }
    }
    
    
    func didFailToConnect(_: CBCentralManager, peripheral: CBPeripheral, error _: Error?) {
        Logger.error("Failed to connect to peripheral: \(peripheral.name ?? "Unnamed")")
        resetConfigure()
        obdConnectionDelegate?.onConnectFailedDevice(device: BluetoothDevice(name: peripheral.name ?? "Unnamed", address: peripheral.identifier.uuidString, rssi: 0, lastSeen: Date()))
    }
    
    func didDisconnect(_: CBCentralManager, peripheral: CBPeripheral, error _: Error?) {
        Logger.info("Disconnected from peripheral: \(peripheral.name ?? "Unnamed")")
        resetConfigure()
        obdConnectionDelegate?.onDisConnectDevice(device: BluetoothDevice(name: peripheral.name ?? "Unnamed", address: peripheral.identifier.uuidString, rssi: 0, lastSeen: Date()))
    }
    
    func connectionEventDidOccur(_: CBCentralManager, event: CBConnectionEvent, peripheral _: CBPeripheral) {
        Logger.error("Connection event occurred: \(event.rawValue)")
    }
    
    func connectAsync(timeout: TimeInterval, address: String? = nil) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.connectionCompletion = { peripheral, error in
                if peripheral != nil {
                    continuation.resume()
                } else if let error = error {
                    continuation.resume(throwing: error)
                }
                
                self.connectionCompletion = nil
            }
            connect(address: address)
        }
        self.connectionCompletion = nil
    }
    
    
    /// Sends a message to the connected peripheral and returns the response.
    /// - Parameter message: The message to send.
    /// - Returns: The response from the peripheral.
    /// - Throws:
    ///     `BLEManagerError.sendingMessagesInProgress` if a message is already being sent.
    ///     `BLEManagerError.missingPeripheralOrCharacteristic` if the peripheral or ecu characteristic is missing.
    ///     `BLEManagerError.incorrectDataConversion` if the data cannot be converted to ASCII.
    ///     `BLEManagerError.peripheralNotConnected` if the peripheral is not connected.
    ///     `BLEManagerError.timeout` if the operation times out.
    ///     `BLEManagerError.unknownError` if an unknown error occurs.
    @discardableResult
    func sendCommand(_ command: String, retries: Int = 3) async throws -> [String] {
        guard sendMessageCompletion == nil else {
            obdConnectionDelegate?.onOBDLog(logs: "\(BLEManagerError.sendingMessagesInProgress)")
            throw BLEManagerError.sendingMessagesInProgress
        }
        
        Logger.info("Sending command: \(command)")
        obdConnectionDelegate?.onOBDLog(logs: "Sending command: \(command)")
        
        guard let connectedPeripheral = connectedPeripheral, let characteristic = ecuWriteCharacteristic else {
            Logger.error("Error: Missing peripheral or ecu characteristic.")
            obdConnectionDelegate?.onOBDLog(logs: "\(BLEManagerError.missingPeripheralOrCharacteristic)")
            throw BLEManagerError.missingPeripheralOrCharacteristic
        }
        
        guard let data = "\(command)\r".data(using: .ascii) else {
            Logger.error("Error: No Data.")
            obdConnectionDelegate?.onOBDLog(logs: "\(BLEManagerError.noData)")
            throw BLEManagerError.noData
        }
        
        return try await Timeout(seconds: 5) {
            try await withCheckedThrowingContinuation { [unowned self] (continuation: CheckedContinuation<[String], Error>) in
                // Set up a timeout timer
                self.sendMessageCompletion = { response, error in
                    if let response {
                        Logger.info("Raw Response: \(response)")
                        self.obdConnectionDelegate?.onOBDLog(logs: "Raw Response: \(response)")
                        continuation.resume(returning: response)
                    } else if let error {
                        Logger.error(error)
                        continuation.resume(throwing: error)
                    }
                    self.sendMessageCompletion = nil
                }
                connectedPeripheral.writeValue(data, for: characteristic, type: .withResponse)
            }
        }
    }
    
    /// Processes the received data from the peripheral.
    /// - Parameters:
    ///  - data: The data received from the peripheral.
    ///  - completion: The completion handler to call when the data has been processed.
    func processReceivedData(_ data: Data, completion _: (([String]?, Error?) -> Void)?) {
        buffer.append(data)
        
        guard let string = String(data: buffer, encoding: .utf8) else {
            buffer.removeAll()
            return
        }
        
        if string.contains(">") {
            var lines = string
                .components(separatedBy: .newlines)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            // remove the last line
            lines.removeLast()
            
//            Logger.debug("Raw Response: \(lines)")
//            obdConnectionDelegate?.onOBDLog(logs: "Raw Response: \(lines)")
            
            if sendMessageCompletion != nil {
                if lines[0].uppercased().contains("NO DATA") {
                    Logger.error("NO Data received from OBD2")
                    sendMessageCompletion?(nil, BLEManagerError.noData)
                } else {
                    sendMessageCompletion?(lines, nil)
                }
            }
            buffer.removeAll()
        }
    }
    
    func scanForPeripherals() async throws {
        startScanning(nil)
        try await Task.sleep(nanoseconds: 10_000_000_000)
        stopScanning()
    }
    
    private func Timeout<R>(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> R) async throws -> R {
        return try await withThrowingTaskGroup(of: R.self) { group in
            // Start actual work.
            group.addTask {
                let result = try await operation()
                try Task.checkCancellation()
                return result
            }
            // Start timeout child task.
            group.addTask {
                if seconds > 0 {
                    try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                }
                try Task.checkCancellation()
                // We’ve reached the timeout.
                if self.foundPeripheralCompletion != nil {
                    self.foundPeripheralCompletion?(nil, BLEManagerError.scanTimeout)
                }
                self.obdConnectionDelegate?.onOBDLog(logs: "\(BLEManagerError.timeout)")
                throw BLEManagerError.timeout
            }
            // First finished child task wins, cancel the other task.
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    func resetSendingMessage() {
        sendMessageCompletion = nil
    }
    
    private func resetConfigure() {
        ecuReadCharacteristic = nil
        ecuWriteCharacteristic = nil
        connectedPeripheral = nil
    }
    
    private func removeLostDevices() {
        let currentTime = Date()
        let timeIntervalThreshold: TimeInterval = 5 // 5초 동안 신호 없으면 제거
        
        deviceListWithPublished.removeAll { device in
            let timeSinceLastSeen = currentTime.timeIntervalSince(device.lastSeen)
            return timeSinceLastSeen > timeIntervalThreshold
        }
    }
}

extension BLEManager : CBCentralManagerDelegate {
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        didDiscover(central, peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        didConnect(central, peripheral: peripheral)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        didUpdateState(central)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        didFailToConnect(central, peripheral: peripheral, error: error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        didDisconnect(central, peripheral: peripheral, error: error)
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        didDiscoverServices(peripheral, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        didDiscoverCharacteristics(peripheral, service: service, error: error)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        didUpdateValue(peripheral, characteristic: characteristic, error: error)
    }
}
