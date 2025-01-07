//
//  HTTPHeader.swift
//  z-car
//
//  Created by Namuplanet on 8/26/24.
//

import Foundation
import UIKit

enum HTTPHeader : String {
    case authorization = "Authorization"
    case accept = "Accept"
    case contentType = "Content-Type"
    case deviceName = "deviceNm"
    case osKind = "osKind"
    case version = "version"
    case serviceKind = "serviceKind"
    case appKind = "appKind"
    case appTypeCd = "appTypeCd"
    
    var value : String {
        switch self {
        case .accept:
            return "*/*"
        case .contentType:
            return "application/json"
        case .deviceName:
//            return UIDevice.current.name // Full Name 사용시 header 오류 발생
            return "iPhone"
        case .osKind:
            return "04"
//        case .version:
//            return Environment.appVersion
        case .serviceKind:
            return "01"
        case .appKind:
            return "02"
        case .appTypeCd:
            return "01" // 앱 구분(01: Z-CAR, 02: Autosaving)
        default :
            return ""
        }
    }
    

}
