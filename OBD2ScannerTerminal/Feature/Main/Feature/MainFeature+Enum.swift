//
//  MainFeature+Enum.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/19/24.
//

import Foundation

extension MainFeature {
    enum PopupPresent {
        case bluetoothRegistration
        case supportedPIDsCheck
    }
    
    enum ID: Hashable {
        case debounce, throttle
    }
    
    enum CommandType : String, CaseIterable {
        case AT, PIDs
        
        var name : String {
            switch self {
            case .AT:
                return "AT"
            case .PIDs:
                return "PIDs"
            }
        }
    }
}
