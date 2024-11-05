//
//  BluetoothDevice.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import Foundation

/// 블루투스 장치 정보
struct BluetoothDevice : Hashable {
    /// 블루투스 장치 이름
    public var name:String
    
    /// 블루투스 장치 주소
    public var address:String
    
    /// 블루투스 장치 신호세기
    public var rssi:Int
    
    public var lastSeen : Date
    
    /// 블루투스 장치 정보 문자열
    ///  - Return: 장치명, 주소, 신호세기
    public var description: String {
        return "BluetoothDevice - name: \(name), address: \(address), rssi: \(rssi)"
    }
}

typealias BluetoothDeviceList = [BluetoothDevice]
