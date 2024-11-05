//
//  OBD2ConnectPopupView.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/5/24.
//

import SwiftUI

struct OBD2ConnectPopupView: View {
    let bluetoothList : BluetoothList
    let selectItem : (BluetoothItem) -> Void
    let searchAction : () -> Void
    let cancleAction : () -> Void
    
    var body: some View {
        VStack(spacing:20) {
            VStack(spacing:15) {
                Text("제트카 OBD II 연결")
                    .fontModifier(fontSize: 20, weight: .bold, color: ColorSystem.green5ea504.rawValue)
                Text("연결할 장치가 켜져 있는지 확인해주세요.")
                    .fontModifier(fontSize: 16, weight: .semibold, color: ColorSystem.black.rawValue)
            }
            
            List(bluetoothList.sorted, id: \.id) { bluetoothItem in
                HStack(alignment: .center, spacing: 10) {
                    Text(bluetoothItem.name)
                        .fontModifier(fontSize: 16, weight: .semibold, color: ColorSystem.gray6e7f8d.rawValue)
                    
                    Image(systemName: "antenna.radiowaves.left.and.right.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 22.5, height: 22.5)
                        .foregroundStyle(Color.colorForRSSI(bluetoothItem.rssi)) // RSSI에 따라 색상이 변경됨
                    
                    Spacer()
                }
                .onTapGesture {
                    selectItem(bluetoothItem)
                }
            }
            .listStyle(.plain)
            .frame(maxWidth: 250, maxHeight: 230)
            .scrollContentBackground(.hidden)
            .background()
            .shadowModifier()
            
                        
            VStack(alignment: .leading, spacing: 12) {
                Text("1. Z-CAR 항목을 클릭하여 연결")
                    .multilineTextAlignment(.leading)
                    .fontModifier(fontSize: 14, weight: .semibold, color: ColorSystem.gray6e7f8d.rawValue)
                
                Text("2. 휴대폰 B/T 성능에 따라 연결시간 발생")
                    .multilineTextAlignment(.leading)
                    .fontModifier(fontSize: 14, weight: .semibold, color: ColorSystem.gray6e7f8d.rawValue)
                
                HStack {
                    Text("3. 초기 비번 ") +
                    Text("1234").foregroundColor(Color(hex: ColorSystem.green5ea504.rawValue)) + Text(" 또는 ")
                     + Text("0000").foregroundColor(Color(hex: ColorSystem.green5ea504.rawValue)) + Text(" 입력")
                }
                .multilineTextAlignment(.leading)
                .fontModifier(fontSize: 14, weight: .semibold, color: ColorSystem.gray6e7f8d.rawValue)
            }
            
            HStack {
                Text("취소")
                    .textTobuttonModifier(fontSize: 15, width: 130, height: 40, textColor: ColorSystem.white.rawValue, bgColor: ColorSystem.gray6e7f8d.rawValue) {
                        cancleAction()
                    }
                
                Text("검색")
                    .textTobuttonModifier(fontSize: 15, width: 130, height: 40, textColor: ColorSystem.white.rawValue, bgColor: ColorSystem.green5ea504.rawValue) {
                        searchAction()
                    }
            }
        }
        .padding(25)
        .background(Color(hex: ColorSystem.whitee4ebf1.rawValue).cornerRadius(10))
    }
}
