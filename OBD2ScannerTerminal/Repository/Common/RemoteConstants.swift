//
//  RemoteConstants.swift
//  zcar
//
//  Created by KyuHo.Son on 2/10/24.
//  Copyright © 2024 com.zcar. All rights reserved.
//

import Foundation

public enum APIVersion: String {
    case v1 = "/v1"
    case v2 = "/v2"
    case empty = ""
}
       
class RemoteConstants {
    static var apiHost: String {
        
        /*
          "https://www.z-car.co.kr/api-ios-test" // 테스트
          "https://qapi.z-car.co.kr/api" // AWS (신규서버, 카이즈유)
          "http://dapi.z-car.co.kr/api" // AWS (신규 테스트서버, 카이즈유)
          "https://api.z-car.co.kr/api" // AWS (서버, 카365) (target)
         
         시뮬레이터 사용시 Test DB
        */
        
        return "http://dapi.z-car.co.kr/api"
    }
    
    static var currentAPIVersion : String {
        return APIVersion.v2.rawValue
    }
    
    static let httpStatusValidRange = Array(200..<300)
    
    enum MimeType: String {
        case imageToJpeg = "image/jpeg"
        case pdf = "application/pdf"
        case text = ""
        
        var value: String {
            self.rawValue
        }
    }
}
