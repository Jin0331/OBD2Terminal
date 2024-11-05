//
//  OBD2Gateway.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import Foundation
import Combine
import CoreBluetooth
import ComposableArchitecture

final class Version {
    public static let number:String = "v1.0.0"
    
    static func printModuleInfo(){
        Logger.info("#####################################################################");
        Logger.info("###################[IOS] OBDGateway Terminal Info####################");
        Logger.info("#####################################################################");
        Logger.info(" >     Specified-Version : " + Version.number);
        Logger.info(" >     Built-By          : Jinwoo (Jinwoo, Lee)");
    }
}

final class OBD2Gateway{
    var scanDelegate:BluetoothScanEventDelegate?
    var connectDelegate: BluetoothConnectionDelegate?
    var messageDelegate: BluetoothMessageDelegate?
    let btConnection = BluetoothConnectionThread.shared
    
    let onDeviceFoundProperty: PassthroughSubject<BluetoothDeviceList, Never> = .init()
    
    
    func setGateway() {
        Version.printModuleInfo()
        messageDelegate = self
        
        btConnection.connectionDelegate = self
        btConnection.scanDelegate = self
        btConnection.start()
    }
    
    /// Z-CAR 블루투스 장치 스캔 요청
    func scanBluetooth() {
        btConnection.startScan(scanDelegate: self)
    }
}

extension OBD2Gateway : BluetoothConnectionDelegate {
    func onConnectingEcu() {
        
    }
    
    func onConnectEcu() {
        
    }
    
    func onFailedEcu() {
        
    }
    
    func onConnectingDevice(device: BluetoothDevice) {
        
    }
    
    func onConnectDevice(device: BluetoothDevice) {
        
    }
    
    func onConnectFailedDevice(device: BluetoothDevice) {
        
    }
    
    func onDisConnectDevice(device: BluetoothDevice) {
        
    }
}

extension OBD2Gateway : BluetoothScanEventDelegate {
    func onDiscoveryStarted() {
        
    }
    
    func onDiscoveryFinised() {
        
    }
    
    func onDeviceFound(device: BluetoothDeviceList) {
        onDeviceFoundProperty.send(device)
    }
}

extension OBD2Gateway : BluetoothMessageDelegate {
    func onReceiveMessage(message: String) {
        
    }
}

private enum OBD2GatewayKey : DependencyKey {
    static var liveValue: OBD2Gateway = OBD2Gateway()
}

extension DependencyValues {
    var obd2Gateway : OBD2Gateway {
        get { self[OBD2GatewayKey.self] }
        set { self[OBD2GatewayKey.self] = newValue}
    }
}

final class BluetoothConnectionThread : BluetoothMessageDelegate {
    
    static let shared = BluetoothConnectionThread()
    private init() { }
    
    var connection : BluetoothConnection!
    var scanDelegate: BluetoothScanEventDelegate?
    var connectionDelegate : BluetoothConnectionDelegate?
    
    func start() {
        self.connection = BluetoothConnection.shared
        
        self.connection.scanDelegate = self.scanDelegate
        self.connection.messageDelegate = self
        self.connection.connectionDelegate = self.connectionDelegate
    }
    
    func startScan(scanDelegate: BluetoothScanEventDelegate)
    {
        connection.startScan(delegate: scanDelegate)
    }
    
    func onReceiveMessage(message: String) {
        
    }
}

final class DefaultScanDelegate: BluetoothScanEventDelegate {
    init() {}
    
    func onDiscoveryStarted(){}
    func onDiscoveryFinised(){}
    func onDeviceFound(device: BluetoothDeviceList){}
    func onDeviceError(){}
}


final class BluetoothConnection : NSObject {
    
    static let shared = BluetoothConnection()
    
    var centralManager : CBCentralManager!
    
    // BluetoothScanEventDelegate 프로토콜에 등록된 메서드를 수행하는 delegate입니다.
    var scanDelegate: BluetoothScanEventDelegate?
    
    // BluetoothMessageDelegate 프로토콜에 등록된 메서드를 수행하는 delegate입니다.
    var messageDelegate: BluetoothMessageDelegate?
    
    // BluetoothConnectionDelegate 프로토콜에 등록된 메서드를 수행하는 delegate입니다.
    var connectionDelegate : BluetoothConnectionDelegate?
    
    // 스캔 블루투스 장치 정보 저장소
    var deviceList = [String: CBPeripheral]()
    var deviceListWithPublished = [BluetoothDevice]()
    
    /// pendingPeripheral은 현재 연결을 시도하고 있는 블루투스 주변기기를 의미합니다.
    weak var pendingPeripheral : CBPeripheral?
    
    /// connectedPeripheral은 연결에 성공된 기기를 의미합니다. 기기와 통신을 시작하게되면 이 객체를 이용하게됩니다.
    var connectedPeripheral : CBPeripheral?
    
    /// 데이터를 주변기기에 보내기 위한 characteristic을 저장하는 변수입니다.
    var writeCharacteristic: CBCharacteristic?
    
    /// 데이터를 주변기기에 보내는 type을 설정합니다. withResponse는 데이터를 보내면 이에 대한 답장이 오는 경우입니다.
    /// withoutResponse는 반대로 데이터를 보내도 답장이 오지 않는 경우입니다.
    let writeType: CBCharacteristicWriteType = .withoutResponse
    
    /// serviceUUID는 Peripheral이 가지고 있는 서비스의 UUID를 뜻합니다. 거의 모든 ELM어댑터 모듈이 기본적으로 갖고있는 FFF0으로 설정하였습니다.
    /// 하나의 기기는 여러개의 serviceUUID를 가질 수도 있습니다.
    let serviceUUID = CBUUID(string: "FFF0")
    
    /// characteristicUUID는 serviceUUID에 포함되어있습니다. 이를 이용하여 데이터를 송수신합니다. FFE0 서비스가 갖고있는 FFE1로 설정하였습니다. 하나의 service는 여러개의 characteristicUUID를 가질 수 있습니다.
    /// Device UUID :  FFF0
    /// Read characteristic : FFF1
    /// Write characteristic : FFF2
    let readCharacteristicUUID  = CBUUID(string : "FFF1")
    let writeCharacteristicUUID = CBUUID(string : "FFF2")
    
    
    override private init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        centralManager.delegate = self
        
        startScan(delegate: DefaultScanDelegate())
    }
    
    func startScan(delegate : BluetoothScanEventDelegate) {
        guard centralManager.state == .poweredOn else { return }
        self.scanDelegate = delegate
        
        // 스캔중이면 스캔종료 후 스캔시작
        if centralManager.isScanning {
            scanDelegate?.onDiscoveryFinised()
        }
        
        deviceList.removeAll()
        deviceListWithPublished.removeAll()
        
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        
        self.scanDelegate?.onDiscoveryStarted()
    }
    
    func stopScan()
    {
        guard centralManager.isScanning else { return }
        centralManager.stopScan()
    }
    
    func connect(address: String){
        Logger.info("Bluetooth address: \(address)")
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
        
        guard name == "Z-CAR" else {
            // 주변 기기와 연결 실패 시 동작하는 코드를 여기에 작성합니다.
            connectionDelegate?.onConnectFailedDevice(device: device)
            return
        }
        
        // 주변 기기와 연결 실패 시 동작하는 코드를 여기에 작성합니다.
        connectionDelegate?.onConnectingDevice(device: device)
        
        // 연결 실패를 대비하여 현재 연결 중인 주변 기기를 저장합니다.
        pendingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect(){
        centralManager.cancelPeripheralConnection(connectedPeripheral!)
    }
    
}

extension BluetoothConnection : CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            // 검색된 모든 service에 대해서 characteristic을 검색합니다. 파라미터를 nil로 설정하면 해당 service의 모든 characteristic을 검색합니다.
            peripheral.discoverCharacteristics([readCharacteristicUUID, writeCharacteristicUUID], for: service)
        }
    }
}


extension BluetoothConnection : CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        pendingPeripheral = nil
        connectedPeripheral = nil
        
        switch central.state {
        case .poweredOn:
            Logger.info(">>> Bluetooth is powered on.")
            // 페어링을 시작하려면 특정 서비스를 가진 장치를 찾기 시작합니다.
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        case .poweredOff:
            Logger.info(">>> Bluetooth is power off.")
        case .resetting:
            Logger.info(">>> Bluetooth is resetting.")
            // 블루투스가 리셋되는 중인 경우, 적절한 처리를 수행합니다.
        case .unauthorized:
            Logger.info(">>> Bluetooth is unauthorized.")
        case .unknown:
            Logger.info(">>> Bluetooth state is unknown.")
            // 블루투스 상태를 알 수 없는 경우, 적절한 처리를 수행합니다.
        case .unsupported:
            Logger.info(">>> Bluetooth is unsupported.")
            // 블루투스를 지원하지 않는 경우, 적절한 처리를 수행합니다.
        @unknown default:
            fatalError("Unhandled Bluetooth state.")
        }
    }
    
    // 기기가 검색될 때마다 호출되는 메서드입니다.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name  = peripheral.name else { return }
        let address     = peripheral.identifier.uuidString
        let rssi        = RSSI.intValue
        
        if peripheral.name == "Z-CAR" {
            deviceList[address] = peripheral
            // 기존에 있던 장치 업데이트 또는 새로 추가
            if let index = deviceListWithPublished.firstIndex(where: { $0.address == address }) {
                deviceListWithPublished[index].rssi = rssi
                deviceListWithPublished[index].lastSeen = Date() // 마지막으로 발견된 시간 업데이트
            } else {
                let newDevice = BluetoothDevice(name: name, address: address, rssi: rssi, lastSeen: Date())
                deviceListWithPublished.append(newDevice)
            }
            
            Logger.info(">>> Found Bluetooth : \(deviceListWithPublished)")
            
            /// 연결가능한 OBD2 발견할 때 마다, 해당 Array update
            if peripheral.state == .disconnected {
                self.connectedPeripheral = peripheral
                self.scanDelegate?.onDeviceFound(device: deviceListWithPublished)
            }
        }
    }
}
