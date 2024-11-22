//
//  OBDService+Delegate.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/19/24.
//

import Foundation

//MARK: - BluetoothScanEventDelegate
extension OBDService :BluetoothScanEventDelegate {
    func onDiscoveryStarted() { }
    
    func onDiscoveryFinised() { }
    
    func onDeviceFound(device: BluetoothDeviceList) {
        Logger.debug("Found device: \(device)")
        addBTList(device)
        onDeviceFoundProperty.send(device)
    }
}

//MARK: - BluetoothConnectionDelegate
extension OBDService : BluetoothConnectionEventDelegate {
    func onConnectingEcu() { }
    
    func onConnectEcu() { }
    
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
        Logger.info("onDisconnectDevice \(device)")
        onDisConnectDeviceProperty.send(device)
    }
    
    func onOBDLog(logs: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            receiveOBD2LogProperty.send(OBD2Log(log: [logs]))
        }
    }
}
