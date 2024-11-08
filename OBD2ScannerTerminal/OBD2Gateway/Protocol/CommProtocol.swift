//
//  CommProtocol.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/7/24.
//

import Foundation
import OSLog
import CoreBluetooth

protocol CommProtocol {
    func sendCommand(_ command: String, retries: Int) async throws -> [String]
    func disconnectPeripheral()
    func connectAsync(timeout: TimeInterval, address: String?) async throws
    func scanForPeripherals() async throws
}
