//
//  OBD2SupportedPopupView.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/11/24.
//

import SwiftUI
import OBDGatewayFramework

struct OBD2SupportedPopupView : View {
    let supportedOBD2Commands: [OBDCommand]
    
    var body: some View {
        VStack(spacing:20) {
            VStack(spacing:15) {
                Text("Supported PIDs")
                    .fontModifier(fontSize: 20, weight: .bold, color: ColorSystem.green5ea504.rawValue)
            }
            
            List(supportedOBD2Commands, id: \.properties.command) { command in
                Text("\(command.properties.command) - \(command.properties.description)")
                    .fontModifier(fontSize: 15, weight: .semibold, color: ColorSystem.gray6e7f8d.rawValue)
            }
            .listStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: 450)
            .scrollContentBackground(.hidden)
            .background()
            .shadowModifier()
        }
        .padding(25)
        .background(Color(hex: ColorSystem.whitee4ebf1.rawValue).cornerRadius(10))
        .padding(.horizontal, 25)
    }
}
