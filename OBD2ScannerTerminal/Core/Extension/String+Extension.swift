//
//  String+Extension.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/7/24.
//

import Foundation

extension String {
    var hexBytes: [UInt8] {
        var position = startIndex
        return (0 ..< count / 2).compactMap { _ in
            defer { position = index(position, offsetBy: 2) }
            return UInt8(self[position ... index(after: position)], radix: 16)
        }
    }
    
    var isHex: Bool {
        return !isEmpty && allSatisfy { $0.isHexDigit }
    }
    
    var toDictionary: [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
        return nil
    }
    var prettyString: String {
        guard let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false), let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject] else {
            return self
        }
        
        return json.description.prettyString
    }}

extension Data {
    func bitCount() -> Int {
        return count * 8
    }
}

