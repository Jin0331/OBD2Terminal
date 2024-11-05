//
//  NormalTextLabelModifier.swift
//  z-car
//
//  Created by Namuplanet on 9/2/24.
//

import Foundation
import SwiftUI

struct NormalTextLabelModifier : ViewModifier {
    var fontSize : CGFloat
    var height : CGFloat
    
    func body(content: Content) -> some View {
        content
            .fontModifier(fontSize: fontSize, weight: .semibold, color: ColorSystem.gray6e7f8d.rawValue)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: height)
            .background {
                RoundedRectangle(cornerRadius: 4)
                    .foregroundColor(Color(hex: ColorSystem.whitee4ebf1.rawValue))
                    .frame(maxWidth: .infinity, maxHeight: height)
            }
    }
}
