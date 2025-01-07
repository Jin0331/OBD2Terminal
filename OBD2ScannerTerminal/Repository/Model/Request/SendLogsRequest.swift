//
//  SendLogsRequest.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 12/19/24.
//

import Foundation

struct SendLogsRequest : Encodable {
    let vin : String
    let iosLog : String
}
