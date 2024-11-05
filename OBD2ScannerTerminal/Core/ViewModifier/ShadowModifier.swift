//
//  ShadowModifier.swift
//  z-car
//
//  Created by Namuplanet on 9/4/24.
//

import SwiftUI

struct ShadowModifier : ViewModifier {
    
    var cornerRadius : CGFloat
    var bgColor : UInt
    var radius : CGFloat
    var x: CGFloat
    var y: CGFloat
    
    func body(content : Content) -> some View {
        content
            .background(Color(hex: bgColor))
            .cornerRadius(cornerRadius)
            .shadow(color: Color(hex: ColorSystem.gray6e7f8d.rawValue).opacity(0.3), radius: radius, x: x, y: y)
    }
}
