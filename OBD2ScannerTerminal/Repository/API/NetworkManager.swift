//
//  NetworkManager.swift
//  z-car
//
//  Created by Namuplanet on 8/26/24.
//

import Foundation
import ComposableArchitecture
import Alamofire

final class NetworkManager {
    
    static let shared = NetworkManager()
    
    private let session: Session = {
        let manager = ServerTrustManager(evaluators: ["qapi.z-car.co.kr" : DisabledTrustEvaluator()])
        let configuration = URLSessionConfiguration.af.default
        return Session(configuration: configuration, serverTrustManager: manager)
    }()
        
    func requestAPI<T:Decodable>(router : URLRequestConvertible, of type : T.Type, isLog : Bool = true) async throws -> T {
        
        var urlRequest =  try router.asURLRequest()
        urlRequest.timeoutInterval = 40
        
        useRequestLog(urlRequest)
        
        return try await withCheckedThrowingContinuation { continuation in
            session.request(urlRequest)
                .validate(statusCode: RemoteConstants.httpStatusValidRange)
                .responseDecodable(of: type, emptyResponseCodes: [200]) { response in
                    switch response.result {
                    case let .success(res):
                        continuation.resume(returning: res)
                        if isLog {
                            self.useResponseLog(data: response.data!)
                        }                        
                        
                    //FIXME: - Error Handligng 필요
                    case let .failure(error):
                        if let errorData = response.data {
                            self.useResponseLog(data: response.data!, error: true)
                            Logger.error(error)
                            do {
                                let networkError = try JSONDecoder().decode(ErrorResponse.self, from: errorData)
                                let apiError = APIError(error: networkError)
                                continuation.resume(throwing: apiError)
                            } catch {
                                // decoding Error
                                continuation.resume(throwing: APIError.decodingError)
                            }
                        } else {
                            continuation.resume(throwing: error)
                        }
                    }
                }
        }
    }
        
    private func useRequestLog(_ urlRequest : URLRequest) {
        
        let head = "┌──────────────────────────────────── [🔷 REQUEST ] ────────────────────────────────────┐"
        let foot = "└───────────────────────────────────────────────────────────────────────────────────────┘"

        var strings: [String] = []
        
        strings.append("\n")
        strings.append("")
        strings.append(head)
        if let url = urlRequest.url?.absoluteString {
            strings.append(url)
        }
        
        if let header = urlRequest.allHTTPHeaderFields {
            strings.append("\(header)")
        }
        
        if let httpBody = urlRequest.httpBody {
            let dictionary = String(decoding: httpBody, as: UTF8.self).toDictionary
            strings.append(dictionary?.prettyString ?? "")
        }
         
        strings.append(foot)
        strings.append("")
        let log = strings.reduce("") { $0 + $1 + "\n" }
        
        DispatchQueue.global(qos: .background).sync {
            Logger.info(log)
        }
    }
    
    private func useResponseLog(data: Data, error : Bool = false) {
        
        let head = error ? "┌──────────────────────────────────── [🚫 ERROR RESPONSE ] ────────────────────────────────────┐" : "┌──────────────────────────────────── [✅ RESPONSE ] ────────────────────────────────────┐"
        
        let foot = "└────────────────────────────────────────────────────────────────────────────────────────┘"
        
        let dictionary = String(decoding: data, as: UTF8.self).toDictionary
        
        var strings: [String] = []
        
        strings.append("\n")
        strings.append(head)
        strings.append(dictionary?.prettyString ?? "")
        strings.append(foot)
        strings.append("\n")
  
        let log = strings.reduce("") { $0 + $1 + "\n" }
        
        DispatchQueue.global(qos: .background).sync {
            Logger.info(log)
        }
    }
}

private enum NetworkManagerKey: DependencyKey {
    static var liveValue: NetworkManager = NetworkManager()
}

extension DependencyValues {
    var networkManager: NetworkManager {
        get { self[NetworkManagerKey.self] }
        set { self[NetworkManagerKey.self] = newValue }
    }
}
