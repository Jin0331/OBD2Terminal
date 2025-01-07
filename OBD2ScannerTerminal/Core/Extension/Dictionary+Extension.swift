//
//  Dictionary+Extension.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 12/19/24.
//

import Foundation

extension Dictionary {
    var jsonSerialization: Data? {
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: self,
                options: JSONSerialization.WritingOptions.prettyPrinted
            )
            return jsonData
        } catch {
            return nil
        }
    }
    
    var prettyString: String {
        guard let data = self.jsonSerialization, let jsonString = String(data: data, encoding: .utf8) else {
            return self.description
        }
        
        return jsonString
    }
}
