//
//  MainStatusItem.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/19/24.
//

import Foundation

struct MainStatusItem : Equatable {
    var bluetoothConnect : Bool = false
    var sendLoading : Bool = false
    var bluetoothConnectPresent : Bool = false
    var supportedPIDsCheckPresnet : Bool = false
}
