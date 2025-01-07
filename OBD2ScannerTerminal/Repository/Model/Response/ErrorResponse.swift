//
//  ErrorResponse.swift
//  z-car
//
//  Created by Namuplanet on 8/27/24.
//

import Foundation

struct ErrorResponse : Decodable {
    let contents : String?
    let code : String
    let message : String
}
