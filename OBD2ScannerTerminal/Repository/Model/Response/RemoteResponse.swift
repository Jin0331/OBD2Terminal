//
//  RemoteResponse.swift
//  z-car
//
//  Created by Namuplanet on 8/27/24.
//

import Foundation

struct RemoteResponse<T:Decodable> : Decodable {
    let code : String
    let message : String
    let contents : T
}
