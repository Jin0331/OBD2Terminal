//
//  MainScreen+Identifiable.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/12/24.
//

import Foundation

extension MainScreen.State: Identifiable {
    var id : ID {
        switch self {
        case .main:
                .main
        }
    }
    
    enum ID : Identifiable {
        case main
        var id: ID { self }
    }
}
