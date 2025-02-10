//
//  MainView+ChildView.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/19/24.
//

import SwiftUI
import ActivityIndicatorView
import ComposableArchitecture
import Combine

extension MainView {
    var headerView: some View {
        HStack(alignment:.center) {
            Text("OBD2\nReset")
                .textTobuttonModifier(fontSize: 15, width: 90, height: 40, textColor: ColorSystem.white.rawValue, bgColor: store.statusItem.bluetoothConnect ?   ColorSystem.green5ea504.rawValue : ColorSystem.gray6e7f8d.rawValue) {
                    store.send(.buttonTapped(.obd2Reset))
                }
                .disabled(!store.statusItem.bluetoothConnect)
            
            Spacer()
            
            if isSendLogButton {
                Text("Send\nLogs")
                    .textTobuttonModifier(fontSize: 15, width: 90, height: 40, textColor: ColorSystem.white.rawValue, bgColor: store.statusItem.bluetoothConnect ?   ColorSystem.green5ea504.rawValue : ColorSystem.gray6e7f8d.rawValue) {
                        store.send(.buttonTapped(.sendLogs))
                    }
                    .disabled(!store.statusItem.bluetoothConnect)
                    .disabled(store.statusItem.logSendLoading)
                    .overlay {
                        if store.statusItem.logSendLoading {
                            ActivityIndicatorView(isVisible: $store.statusItem.logSendLoading,
                                                  type: .flickeringDots(count: 8))
                            .frame(width: 25, height: 25)
                            .foregroundColor(.red)
                        }
                    }
            }
            
            Spacer()
            
            Image(store.statusItem.bluetoothConnect ? .zcarConnect : .zcarUnconnect)
                .resizable()
                .frame(width: 55, height: 55)
                .asButton {
                    if store.statusItem.bluetoothConnect {
                        store.send(.buttonTapped(.bluetoothDisconnect))
                    } else {
                        store.send(.buttonTapped(.bluetoothRegistration))
                    }
                }
        }
        .padding(.bottom, 10)
    }
    
    var bodyView: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                ForEach(store.obdLog.indices, id: \.self) { index in
                    Text(store.obdLog[index])
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(index % 2 == 0 ? Color(.systemGray6) : Color(.white)) // 배경색 번갈아 가며 설정
                        .cornerRadius(4)
                }
                .animation(.easeIn(duration: 0.2), value: store.obdLog)
                .onReceive(cursorPublisher
                    .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)) {
                        if let lastLogIndex = store.obdLog.indices.last {
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
                
                ShareLink(item: store.obdLog.joined(separator: "\n"), label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                })
            }
        }
        .onChange(of: store.obdLog) { _ in
            cursorPublisher.send(())
        }
        .background(Color(.systemGray5))
        .cornerRadius(4)
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    var bottomView: some View {
        HStack {
            Picker("CommandType", selection: $store.commandType) {
                ForEach(MainFeature.CommandType.allCases, id: \.self) { type in
                    Text(type.name)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 120)
            .clipped()
            .disabled(!store.statusItem.bluetoothConnect)
            
            
            if store.statusItem.bluetoothConnect {
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
                    .background(store.statusItem.bluetoothConnect ? Color.init(hex: ColorSystem.green5ea504.rawValue) : Color.init(hex: ColorSystem.gray6e7f8d.rawValue))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .asButton {
                        store.send(.buttonTapped(.sendMessage))
                    }
                    .disabled(!store.statusItem.bluetoothConnect)
                    .disabled(store.statusItem.sendLoading)
                    .overlay {
                        if store.statusItem.sendLoading {
                            ActivityIndicatorView(isVisible: $store.statusItem.sendLoading,
                                                  type: .flickeringDots(count: 8))
                            .frame(width: 25, height: 25)
                            .foregroundColor(.red)
                        }
                    }
            }
        }
    }
}

