//
//  ContentView.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import SwiftUI
import ComposableArchitecture
import PopupView

struct ContentView: View {
    
    @State var store : StoreOf<ContentFeature>
    
    var body: some View {
        WithPerceptionTracking {
            VStack {
                HStack {
                    Spacer()
                    Image(store.bluetoothConnect ? .zcarConnect : .zcarUnconnect)
                        .asButton {
                            if store.bluetoothConnect {
                                store.send(.buttonTapped(.bluetoothDisconnect))
                            } else {
                                store.send(.buttonTapped(.bluetoothRegistration))
                            }
                        }
                }
                
                HStack {
                    TextField("Type OBD2 Command", text: $store.userCommand)
                        .normalTextFieldModifier(height: 45)
                    
                    Text("Send")
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 50, height: 45)
                        .foregroundStyle(Color.init(hex: ColorSystem.white.rawValue))
                        .background(Color.init(hex: ColorSystem.green5ea504.rawValue))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .asButton {
                            store.send(.buttonTapped(.sendMessage))
                        }
                }
            }
            .padding()
            .onAppear {
                store.send(.viewTransition(.onAppear))
            }
            .popup(item: $store.popupPresent) { popup in
                switch popup {
                case .bluetoothRegistration:
                    OBD2ConnectPopupView(bluetoothItemList: store.bluetoothItemList) { item in
                        Logger.debug("item: \(item)")
                        store.send(.buttonTapped(.bluetoothConnect(item)))
                    } searchAction: {
                        store.send(.buttonTapped(.bluetoothScanStart))
                    } cancleAction: {
                        store.send(.viewTransition(.popupDismiss))
                    }

                }
            } customize: {
                $0
                    .isOpaque(true)
                    .closeOnTap(false)
                    .closeOnTapOutside(false)
                    .dragToDismiss(false)
                    .backgroundView {
                        PopupBackgroundView(value: 0.4)
                    }
            }

        }
    }
}

#Preview {
    ContentView(store: Store(initialState: ContentFeature.State(), reducer: {
        ContentFeature()
    }))
}
