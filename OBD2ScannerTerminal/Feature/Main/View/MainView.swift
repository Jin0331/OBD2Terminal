//
//  MainView.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import SwiftUI
import ComposableArchitecture
import ActivityIndicatorView
import PopupView
import Combine

struct MainView: View {
    @State var store : StoreOf<MainFeature>
    @State private var cursorPublisher = PassthroughSubject<Void, Never>()
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing : 10) {
                HStack(alignment:.center) {
                    Text("Supported\nPIDs")
                        .textTobuttonModifier(fontSize: 15, width: 90, height: 40, textColor: ColorSystem.white.rawValue, bgColor: store.bluetoothConnect ?   ColorSystem.green5ea504.rawValue : ColorSystem.gray6e7f8d.rawValue) {
                            store.send(.buttonTapped(.supportedPIDs))
                        }
                        .disabled(!store.bluetoothConnect)
                    
                    Text("OBD2\nReset")
                        .textTobuttonModifier(fontSize: 15, width: 90, height: 40, textColor: ColorSystem.white.rawValue, bgColor: store.bluetoothConnect ?   ColorSystem.green5ea504.rawValue : ColorSystem.gray6e7f8d.rawValue) {
                            store.send(.buttonTapped(.obd2Reset))
                        }
                        .disabled(!store.bluetoothConnect)
                    
                    
                    Spacer()
                    
                    Image(store.bluetoothConnect ? .zcarConnect : .zcarUnconnect)
                        .resizable()
                        .frame(width: 55, height: 55)
                        .asButton {
                            if store.bluetoothConnect {
                                store.send(.buttonTapped(.bluetoothDisconnect))
                            } else {
                                store.send(.buttonTapped(.bluetoothRegistration))
                            }
                        }
                }
                .padding(.bottom, 10)
                
                WithPerceptionTracking {
                    ScrollViewReader { scrollViewProxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(store.obdLog.log.indices, id: \.self) { index in
                                    Text(store.obdLog.log[index])
                                        .font(.system(size: 15, weight: .regular, design: .monospaced))
                                        .padding(.horizontal)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(index % 2 == 0 ? Color(.systemGray6) : Color(.white)) // 배경색 번갈아 가며 설정
                                        .cornerRadius(4)
                                }
                            }
                            .animation(.easeIn(duration: 0.2), value: store.obdLog.log)
                            .onChange(of: store.obdLog.log) { _ in
                                cursorPublisher.send(())
                            }
                            .onReceive(cursorPublisher
                                .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)) {
                                    if let lastLogIndex = store.obdLog.log.indices.last {
                                        scrollViewProxy.scrollTo(lastLogIndex, anchor: .bottom)
                                    }
                                }
                        }
                        .contextMenu {
                            Button {
                                store.send(.buttonTapped(.logClear))
                            } label: {
                                Label("Terminal Clear", systemImage: "eraser")
                            }
                            
                            ShareLink(item: store.obdLog.log.joined(separator: "\n"), label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            })
                        }
                    }
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
                
                HStack {
                    Picker("CommandType", selection: $store.commandType) {
                        ForEach(MainFeature.CommandType.allCases, id: \.self) { type in
                            Text(type.name)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 120)
                    .clipped()
                    .disabled(!store.bluetoothConnect)
                    
                    
                    if store.bluetoothConnect {
                        TextField("Type OBD2 Command", text: $store.userCommand)
                            .normalTextFieldModifier(height: 45)
                    } else {
                        TextField("Connect the OBD2 scanner using the top button.", text: $store.userCommand)
                            .normalTextFieldModifier(height: 45, fontSize: 12)
                            .disabled(true)
                    }
                    
                    ZStack {
                        Text("Send")
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 50, height: 45)
                            .foregroundStyle(Color.init(hex: ColorSystem.white.rawValue))
                            .background(store.bluetoothConnect ? Color.init(hex: ColorSystem.green5ea504.rawValue) : Color.init(hex: ColorSystem.gray6e7f8d.rawValue))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .asButton {
                                store.send(.buttonTapped(.sendMessage))
                            }
                            .disabled(!store.bluetoothConnect)
                            .disabled(store.sendLoading)
                            .overlay {
                                if store.sendLoading {
                                    ActivityIndicatorView(isVisible: $store.sendLoading,
                                                          type: .flickeringDots(count: 8))
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.red)
                                }
                            }
                    }
                }
            }
            .animation(.easeIn(duration: 0.5), value: store.bluetoothConnect)
            .padding()
            .onAppear {
                store.send(.viewTransition(.onAppear))
            }
            .popup(isPresented: $store.bluetoothConnectPresent) {
                OBD2ConnectPopupView(bluetoothItemList: store.bluetoothItemList) { item in
                    Logger.debug("item: \(item)")
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
            .popup(isPresented: $store.supportedPIDsCheckPresnet) {
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

//#Preview {
//    ContentView(store: Store(initialState: ContentFeature.State(), reducer: {
//        ContentFeature()
//    }))
//}
