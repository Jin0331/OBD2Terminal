//
//  EventDelegate.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import Foundation

protocol BluetoothScanEventDelegate {
    /// 블루투스 스캔 시작 이벤트
    func onDiscoveryStarted()

    /// 블루투스 스캔 종료 이벤트
    func onDiscoveryFinised()

    /// 블루투스 장치 발견 이벤트
    ///
    /// - Parameters:
    ///   - device: 대상 블루투스 장치 정보
    func onDeviceFound(device: BluetoothDeviceList)
}

protocol BluetoothConnectionDelegate {
    /// ECU 연결 중 이벤트
    func onConnectingEcu()
    
    /// ECU 연결 완료 이벤트
    func onConnectEcu()
    
    /// ECU 연결 실패 이벤트
    func onFailedEcu()
    
    /// 블루투스 연결 중 이벤트
    ///
    /// - Parameters:
    ///   - device: 대상 블루투스 장치 정보
    func onConnectingDevice(device: BluetoothDevice)
    
    /// 블루투스 연결 완료 이벤트
    ///
    /// - Parameters:
    ///   - device: 대상 블루투스 장치 정보
    func onConnectDevice(device: BluetoothDevice)
    
    /// 블루투스 연결 실패 이벤트
    ///
    /// - Parameters:
    ///   - device: 대상 블루투스 장치 정보
    func onConnectFailedDevice(device: BluetoothDevice)
    
    /// 블루투스 연결 종료 이벤트
    ///
    /// - Parameters:
    ///   - device: 대상 블루투스 장치 정보
    func onDisConnectDevice(device: BluetoothDevice)

}

/// ECU 데이터 수신을 위한 이벤트 프로토콜
protocol BluetoothMessageDelegate {
    /// ECU 데이터 수신 이벤트
    ///
    /// - Parameters:
    ///   - message: 수신 메시지
    func onReceiveMessage(message: String)
}
