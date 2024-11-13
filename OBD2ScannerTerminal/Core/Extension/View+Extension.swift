//
//  View+Extension.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 8/27/24.
//

import Foundation
import SwiftUI

extension View {
    func asButton(action: @escaping () -> Void ) -> some View {
        modifier(ButtonWrapper(action: action))
    }
        
    // Output용
    func normalTextFieldModifier(height: CGFloat, fontSize:CGFloat = 16, weight:Font.Weight = .regular, fontColor:UInt = ColorSystem.black.rawValue, bgColorHex: UInt = ColorSystem.whitee4ebf1.rawValue, alignment : TextAlignment = .leading) -> some View {
        modifier(NormalTextFieldModifier(height: height, fontSize: fontSize, weight: weight, fontColor: fontColor, bgColorHex: bgColorHex, alignment: alignment))
    }
    
    func normalTextLabelModifier(height: CGFloat, fontSize: CGFloat) -> some View {
        modifier(NormalTextLabelModifier(fontSize: fontSize, height: height))
    }
    
    func textBackgroundModifier(width:CGFloat, height:CGFloat, cornerRadius:CGFloat, bgColor:UInt) -> some View {
        modifier(TextBackgroundModifier(width: width, height: height, cornerRadius: cornerRadius, bgColor: bgColor))
    }
    
    func normalTextLabelModifier(width:CGFloat, height:CGFloat, fontSize:CGFloat, bgColor:UInt = ColorSystem.white.rawValue, alignment : Alignment = .trailing) -> some View {
        modifier(NormalTextLabelModifier2(fontSize: fontSize, width: width, height: height, alignment: alignment, bgColor: bgColor))
    }

    func shadowModifier(cornerRadius : CGFloat = 15, bgColor : UInt = ColorSystem.whitee4ebf1.rawValue, radius:CGFloat = 2, x:CGFloat = 7, y:CGFloat = 7) -> some View {
        modifier(ShadowModifier(cornerRadius:cornerRadius, bgColor: bgColor, radius: radius, x: x, y: y))
    }
    
    func fontModifier(fontSize : CGFloat, weight : Font.Weight, color : UInt) -> some View {
        modifier(FontModifier(fontSize: fontSize, weight: weight, color: Color(hex: color)))
    }
    
    func dynamicFontSizeModifier(lineLimit : Int = 1, scaleFactor : CGFloat = 0.01) -> some View {
        modifier(DynamicFontSizeModifier(lineLimit: lineLimit, scaleFactor: scaleFactor))
    }
    
    func textTobuttonModifier(fontSize : CGFloat, weight : Font.Weight = .bold, width : CGFloat, height:CGFloat, cornerRadius : CGFloat = 4, textColor : UInt, bgColor : UInt, isButton: Bool = true,action: @escaping () -> Void) -> some View{
        modifier(TextToButtonModifier(fontSize: fontSize, weight: .bold, width: width, height: height, cornerRadius: cornerRadius, textColor: textColor, bgColor: bgColor, isButton:isButton, action: action))
    }
    
    func profileImageModifier(width : CGFloat, height : CGFloat, horizontalPadding : CGFloat) -> some View {
        modifier(ProfileImageModifier(width: width, height: height, horizontalPadding: horizontalPadding))
    }
    
    func navigationBarColor(backgroundColor: UIColor?, titleColor: UIColor?) -> some View {
        modifier(NavigationBarModifier(backgroundColor: backgroundColor, titleColor: titleColor))
    }
    
    func redactedModifier(_ isVisible : Bool, redactedType : RedactedModifier.RedactedType = .blur) -> some View {
        modifier(RedactedModifier(isVisible: isVisible, redactedType: redactedType))
    }
}

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif
