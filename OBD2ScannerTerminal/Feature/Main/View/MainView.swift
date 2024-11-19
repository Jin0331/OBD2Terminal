//
//  MainView.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import SwiftUI
import ComposableArchitecture
import PopupView
import Combine

struct MainView: View {
    @State var store : StoreOf<MainFeature>
    @State var cursorPublisher = PassthroughSubject<Void, Never>()
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing : 10) {
                headerView
                bodyView
                bottomView
            }
            .animation(.easeIn(duration: 0.5), value: store.statusItem.bluetoothConnect)
            .padding()
            .onAppear {
                store.send(.viewTransition(.onAppear))
            }
            .popup(isPresented: $store.statusItem.bluetoothConnectPresent) {
                OBD2ConnectPopupView(bluetoothItemList: store.bluetoothItemList) { item in
                    store.send(.buttonTapped(.bluetoothConnect(item)))
                } searchAction: {
                    store.send(.buttonTapped(.bluetoothScanStart))
                } cancleAction: {
                    store.send(.viewTransition(.popupDismiss))
                }
            } customize : {
                $0
                    .closeOnTap(false)
                    .closeOnTapOutside(false)
                    .dragToDismiss(false)
                    .backgroundView {
                        PopupBackgroundView(value: 0.4)
                    }
            }
            .popup(isPresented: $store.statusItem.supportedPIDsCheckPresnet) {
                OBD2SupportedPopupView(supportedOBD2Commands: store.obdInfo.supportedPIDsToString)
            } customize : {
                $0
                    .isOpaque(true)
                    .closeOnTap(false)
                    .closeOnTapOutside(true)
                    .dragToDismiss(false)
                    .backgroundView {
                        PopupBackgroundView(value: 0.4)
                    }
            }
        }
    }
}
