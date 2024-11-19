//
//  MainFeature.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct MainFeature {
    @ObservableState
    struct State : Equatable {
        let id = UUID()
        @Shared(Environment.SharedInMemoryType.obdLog.keys) var obdLog : OBD2Log = .init(log: ["OBD2 Terminal Start..."])
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
        case anyAction(AnyAction)
        case provider(Provider)
    }
    
    enum ButtonTapped {
        case bluetoothScanStart
        case bluetoothConnect(BluetoothItem)
        case bluetoothDisconnect
        case bluetoothRegistration
        case sendMessage
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
        
        case requestAT
        case requestPID
        case supportedPID(OBDInfo)
    }
    
    enum AnyAction {
        case addLogSeperate
        case addLogRes([OBDCommand : MeasurementResult])
        case errorHandling(Error)
    }
    
    @Dependency(\.obdService) var obdService
    
    var body : some ReducerOf<Self> {
        
        BindingReducer()
        
        viewTransitionReducer()
        buttonTappedReducer()
        providerReducer()
        anyActionReducer()
    }
}
