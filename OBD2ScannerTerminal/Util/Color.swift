//
//  Color.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/5/24.
//

import SwiftUI

enum ColorSystem: UInt {
    case black = 0xFF000000
    case white = 0xFFFFFFFF
    
    case black000000 = 0x000000
    case black222222 = 0x222222
    case black333333 = 0x333333
    case black384255 = 0x384255
    
    case gray97999e = 0x97999e
    case graycccccc = 0xcccccc
    case graye3e5ec = 0xE3E5EC
    case grayd8d8d8 = 0xD8D8D8
    case gray999999 = 0x999999
    case gray555555 = 0x555555
    case graye8e8e8 = 0xE8E8E8
    case gray1e2834 = 0x1E2834
    case gray6e7f8d = 0x6E7F8D // textUnPointColor
    
    case whiteffffff = 0xFFFFFF
    case whitebcc1c6 = 0xBCC1C6
    case white46ffffff = 0x46FFFFFF
    case whiteeff2f5 = 0xEFF2F5
    case whitee4ebf1 = 0xE4EBF1 //textInputBackground
    case whiteeeeeee = 0xEEEEEE
    
    case redff7f00 = 0xFF7F00
    case redff0000 = 0xFF0000
    case rede31c25 = 0xE31C25
    
    case orangefa0 = 0xFA0
    case orangee58903 = 0xE58903
    
    case yellowfee500 = 0xFEE500
    case yellowffbd03 = 0xFFBD03
    case yellowe7d532 = 0xE7D532
    case yellowe4d232 = 0xE4D232
    case yellowffa200 = 0xFFA200
    
    case green4ac687 = 0x4AC687
    case green7abd87 = 0x7ABD87
    case green668d4e = 0x668D4E
    case green5ea504 = 0x5EA504 // pointColor
    case green04be74 = 0x04BE74
    case green00c73c = 0x00C73C
    
    case blue4e93f3 = 0x4E93F3
    case blue0a1624 = 0x0A1624
    case blue049cbe = 0x049CBE
    case blue073b4c = 0x073B4C
    case blue16B2B6 = 0x16B2B6
    
    var uIntToString: String {
        return String(format: "%06X", self.rawValue)
    }
}



//MARK: - SwiftUI
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

//MARK: - RSSI 값 변경 목적
extension Color {
    static func colorForRSSI(_ rssi: Int) -> Color {
        // RSSI 값을 0 (가장 강한)에서 -100 (가장 약한)으로 설정
        let normalizedValue = Double(rssi + 100) / 100.0
        
        // 약한 신호 (빨간색)에서 강한 신호 (초록색)으로 색상 변화
        return Color(red: 1.0 - normalizedValue, green: normalizedValue, blue: 0.0)
    }
}

//MARK: - UIKit
extension UIColor {
    convenience init(hexCode: String, alpha: CGFloat = 1.0) {
        var hexFormatted: String = hexCode.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).uppercased()
        
        if hexFormatted.hasPrefix("#") {
            hexFormatted = String(hexFormatted.dropFirst())
        }
        
//        assert(hexFormatted.count == 6, "Invalid hex code used.")
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        self.init(red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
                  green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
                  blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
                  alpha: alpha)
    }
}

