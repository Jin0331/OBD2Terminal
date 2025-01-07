//
//  OBD2TerminalRouter.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 8/26/24.
//

import Foundation
import Alamofire

enum OBD2TerminalRouter {
    case sendLogs(SendLogsRequest)
}

extension OBD2TerminalRouter : TargetType {
    var baseURL: URL {
        switch self {
        case .sendLogs:
            return url()
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .sendLogs:
            return .post
        }
    }
    
    var path: String {
        switch self {
        case .sendLogs:
            return "obd2/ios-log"
        }
    }
    
    var header: [String : String] {
        switch self {
        case .sendLogs:
            return adpat()
        }
    }
    
    var parameter: Parameters? {
        return nil
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
    
    var body: Data? {
        switch self {
        case let .sendLogs(request):
            let encoder = JSONEncoder()
            return try? encoder.encode(request)
        }
    }
}
