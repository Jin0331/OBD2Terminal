//
//  Loading.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 9/1/24.
//

import SwiftUI
import ComposableArchitecture
import ActivityIndicatorView

struct LoadingView: View {
    @Binding var showLoadingIndicator : Bool
    var loadingType : ActivityIndicatorView.IndicatorType = .growingCircle
    var value : Double
    var bg : Bool = true
    
    var body: some View {
        VStack {
            ZStack {
                if bg {
                    Color.black.opacity(value)
                        .edgesIgnoringSafeArea(.all)
                        .zIndex(0)
                }
                
                ActivityIndicatorView(isVisible: $showLoadingIndicator, type: .scalingDots())
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color.init(hex: ColorSystem.green5ea504.rawValue))
                    .zIndex(1)
            }
        }
    }
}
