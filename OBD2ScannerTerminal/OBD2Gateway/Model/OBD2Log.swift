//
//  OBD2Log.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/13/24.
//

import Foundation

struct OBD2Log : Equatable, Sendable {
    var log: [String]
    
    mutating func append(_ log: String) {
        self.log.append(log)
    }
}
