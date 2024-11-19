//
//  OBDInfo.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/7/24.
//

import Foundation

enum ECUHeader {
    static let ENGINE = "7E0"
}

struct OBDInfo: Codable, Hashable {
    public var vin: String?
    public var supportedPIDs: [OBDCommand]?
    public var obdProtocol: PROTOCOL?
    public var ecuMap: [UInt8: ECUID]?
    
    var supportedPIDsToString : [OBDCommand] {
        guard let supportedPIDs else { return .init() }
        let orderedPIDs = supportedPIDs.sorted { $0.properties.command < $1.properties.command }
                
        return orderedPIDs
    }
}
