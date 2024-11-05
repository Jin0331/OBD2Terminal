//
//  PopupBackground.swift
//  z-car
//
//  Created by Namuplanet on 9/1/24.
//

import SwiftUI

struct PopupBackgroundView: View {
    
    let value : Double
    
    var body: some View {
        Color.black.opacity(value) // 0.4는 40% 불투명도, 필요에 따라 조정 가능
            .ignoresSafeArea(edges: .all)
    }
}
