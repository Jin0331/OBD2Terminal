//
//  NetworkManager+Auth.swift
//  z-car
//
//  Created by Namuplanet on 8/27/24.
//

import Foundation
import Alamofire

extension NetworkManager {
    func sendLogs(request : SendLogsRequest) async -> Result<String, APIError> {
        do {
            let response = try await requestAPI(router: OBD2TerminalRouter.sendLogs(request), of: RemoteResponse<String>.self)
            return .success(response.contents)
        } catch {
            if let apiError = error as? APIError {
                return .failure(apiError)
            } else {
                return .failure(APIError.unknown)
            }
        }
    }
}
