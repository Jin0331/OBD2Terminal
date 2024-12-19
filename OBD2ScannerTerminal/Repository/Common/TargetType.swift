//
//  TargetType.swift
//  z-car
//
//  Created by Namuplanet on 8/26/24.
//

import Foundation
import Alamofire

protocol TargetType : URLRequestConvertible {
    var baseURL : URL { get }
    var method : HTTPMethod { get }
    var path : String { get }
    var header : [String:String] { get }
    var parameter : Parameters? { get }
    var queryItems : [URLQueryItem]? { get }
    var body : Data? { get }
}

extension TargetType {
    func asURLRequest() throws -> URLRequest {
        let url = URL(string : baseURL.appendingPathComponent(path).absoluteString.removingPercentEncoding!)
        
        var request = URLRequest.init(url: url!)
        
        request.headers = HTTPHeaders(header)
        request.httpMethod = method.rawValue
        request.httpBody = body

        return try URLEncoding.default.encode(request, with: parameter)
    }
    
    func url() -> URL {
        return URL(string: "\(RemoteConstants.apiHost)\(RemoteConstants.currentAPIVersion)")!
    }
    
    func adpat() -> [String:String] {
        return setDefaultHTTPHeaderField()
    }
    
    private func setDefaultHTTPHeaderField() -> [String:String] {

        return [
            HTTPHeader.accept.rawValue: HTTPHeader.accept.value,
            HTTPHeader.contentType.rawValue: HTTPHeader.contentType.value,
            HTTPHeader.deviceName.rawValue: HTTPHeader.deviceName.value,
            HTTPHeader.osKind.rawValue: HTTPHeader.osKind.value,
            HTTPHeader.version.rawValue: HTTPHeader.version.value,
            HTTPHeader.serviceKind.rawValue: HTTPHeader.serviceKind.value,
            HTTPHeader.appKind.rawValue: HTTPHeader.appKind.value,
            HTTPHeader.appTypeCd.rawValue: HTTPHeader.appTypeCd.value
        ]
    }
}
