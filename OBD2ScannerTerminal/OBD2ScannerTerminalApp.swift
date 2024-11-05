//
//  OBD2ScannerTerminalApp.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import SwiftUI
import ComposableArchitecture

@main
struct OBD2ScannerTerminalApp: App {
    init() {
        Logger.configurations()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: ContentFeature.State(), reducer: {
                ContentFeature()
            }))
        }
    }
}
