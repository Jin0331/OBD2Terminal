//
//  EventDelegate.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/8/24.
//

import Foundation

/// 블루투스 스캔에 관련된 이벤트 프로토콜
protocol BluetoothScanEventDelegate{

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

/// 블루투스를 연결 및 ECU연결 과정에 관련된 이벤트 프로토콜
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

    /// 블루투스 자동 연결 실패 이벤트
    func onAutoConnectFailedDevice()
    
    /// 블루투스 미승인 이벤트
    func onUnauthorizedDevice()
    
    /// 블루투스 에러 관련
    func onDeviceError()
    
    /// 블루투스 연결 종료 이벤트
    ///
    /// - Parameters:
    ///   - device: 대상 블루투스 장치 정보
    func onDisConnectDevice(device: BluetoothDevice)
}
