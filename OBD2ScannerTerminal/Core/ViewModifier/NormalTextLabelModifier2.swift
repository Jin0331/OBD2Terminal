//
//  NormalTextLabelModifier2.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 9/2/24.
//

import SwiftUI

struct NormalTextLabelModifier2: ViewModifier {
    let fontSize : CGFloat
    let width : CGFloat
    let height : CGFloat
    let alignment : Alignment
    let bgColor : UInt
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(Color(hex: ColorSystem.gray6e7f8d.rawValue))
            .font(.system(size: fontSize, weight: .bold))
            .background(Color(hex: bgColor))
            .frame(width: width, height: height, alignment: alignment)
    }
}
