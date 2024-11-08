//
//  BatchedResponse.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/7/24.
//

import Foundation

struct BatchedResponse {
    private var response: Data
    private var unit: MeasurementUnit
    init(response: Data, _ unit: MeasurementUnit) {
        self.response = response
        self.unit = unit
    }

    mutating func extractValue(_ cmd: OBDCommand) -> MeasurementResult? {
        let properties = cmd.properties
        let size = properties.bytes
        guard response.count >= size else { return nil }
        let valueData = response.prefix(size)

        response.removeFirst(size)
        //        print("Buffer: \(buffer.compactMap { String(format: "%02X ", $0) }.joined())")
        let result = cmd.properties.decode(data: valueData, unit: unit)

        switch result {
            case .success(let measurementResult):
                return measurementResult.measurementResult
        case .failure(let error):
            print("Failed to decode \(cmd.properties.command): \(error.localizedDescription)")
            return nil
        }
    }
}
