//
//  MainFeature.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import Foundation
import ComposableArchitecture
import OBDGatewayFramework

@Reducer
struct MainFeature {
    @ObservableState
    struct State : Equatable {
        let id = UUID()
        
        var obdLog : [String] = ["OBD2 Terminal Start..."]
        
        var obdInfo : OBDInfo = .init()
        var bluetoothItemList : BluetoothItemList = .init()
        var userCommand : String = .init()
        var commandType : CommandType = .PIDs
        var statusItem : MainStatusItem = .init()
    }
    
    enum Action : BindableAction {
        case binding(BindingAction<State>)
        case buttonTapped(ButtonTapped)
        case viewTransition(ViewTransition)
        case provider(Provider)
        case networkResponse(NetworkResponse)
        case anyAction(AnyAction)
    }
    
    enum ButtonTapped {
        case bluetoothScanStart
        case bluetoothConnect(BluetoothItem)
        case bluetoothDisconnect
        case bluetoothRegistration
        case sendMessage
        case sendLogs
        case supportedPIDs
        case obd2Reset
        
        case logClear
        case logShared
    }
    
    enum ViewTransition {
        case onAppear
        case popupDismiss
        case loadingOn
        case loadingOff
    }
    
    enum Provider {
        case registerPublisher
        case onDeviceFoundProperty(BluetoothDeviceList)
        case onConnectEcuProperty
        case onConnectFailedDeviceProperty(BluetoothDevice)
        case onDisConnectDeviceProperty(BluetoothDevice)
        case receiveOBD2LogProperty(OBDLog)
        
        case requestAT
        case requestPID
        case supportedPID(OBDInfo)
    }
    
    enum NetworkResponse {
        case sendLog(Result<String, APIError>)
    }
    
    enum AnyAction {
        case addLogSeperate
        case addLogRes([OBDCommand : DecodeResult])
        case errorHandling(Error)
    }
    
    @Dependency(\.networkManager) var networkManager
    
    var body : some ReducerOf<Self> {
        
        BindingReducer()
        
        viewTransitionReducer()
        buttonTappedReducer()
        providerReducer()
        networkResponseReducer()
        anyActionReducer()
    }
}
