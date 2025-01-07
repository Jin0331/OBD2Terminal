//
//  APIError.swift
//  Teams
//
//  Created by JinwooLee on 6/10/24.
//

import Foundation

enum APIError : Error, Equatable, LocalizedError {
    case network(errorCode: String, message: String)
    case decodingError
    case unknown
    
    var errorDescription: String {
        switch self {
        case let .network(errorCode, _):
            return errorCode
        case .decodingError:
            return "디코딩 에러"
        case .unknown:
            return "내부 서버 오류"
        }
    }
    
    var errorMessage : String {
        switch self {
        case let .network(_, message):
            return message
        default :
            return ""
        }
    }
        
    enum ErrorType {
        case E30006(message:String)
        case E41001(message:String)
        case E40003(message:String)
        case E00002(message:String)
        case unknown
        
        var errorMessage: String {
            switch self {
            case let .E30006(message),
                 let .E41001(message),
                 let .E40003(message),
                let .E00002(message):
                return message
            case .unknown:
                return ""
            }
        }
    }
    
    init(error : ErrorResponse) {
        self = .network(errorCode: error.code, message: error.message)
    }
    
    static func networkErrorType(error : APIError) -> ErrorType {
        switch error.errorDescription {
        case "30006":
            return .E30006(message: error.errorMessage)
        case "41001":
            return .E41001(message: error.errorMessage)
        case "40003":
            return .E40003(message: error.errorMessage)
        case "00002":
            return .E00002(message: error.errorMessage)
        default:
            return .unknown
        }
    }
}
