//
//  ContentFeature.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import Foundation
import ComposableArchitecture

@Reducer
struct ContentFeature {
    @ObservableState
    struct State : Equatable {
        let id = UUID()
        var bluetoothItemList : BluetoothItemList = .init()
        var bluetoothConnect : Bool = false
        var userCommand : String = .init()
        @Shared(Environment.SharedInMemoryType.obdLog.keys) var obdLog : [String] = ["OBD2 Terminal Start..."]
        
        var popupPresent : PopupPresent?
    }
    
    enum Action : BindableAction {
        case binding(BindingAction<State>)
        case networkResponse(NetworkReponse)
        case buttonTapped(ButtonTapped)
        case viewTransition(ViewTransition)
        case anyAction(AnyAction)
        case provider(Provider)
    }
    
    enum NetworkReponse {
        
    }
    
    enum ButtonTapped {
        case bluetoothScanStart
        case bluetoothConnect(BluetoothItem)
        case bluetoothDisconnect
        case bluetoothRegistration
        case sendMessage
    }
    
    enum ViewTransition {
        case onAppear
        case popupDismiss
    }

    enum Provider {
        case registerPublisher
        case onDeviceFoundProperty(BluetoothDeviceList)
    }
    
    enum AnyAction {
        case logClear
    }
    
    @Dependency(\.obdService) var obdService
    
    var body : some ReducerOf<Self> {
        
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            
            case .viewTransition(.onAppear):
                
                return .run { send in
                    await send(.provider(.registerPublisher))
                }
                
            case .viewTransition(.popupDismiss):
                state.bluetoothItemList = .init()
                state.popupPresent = nil
            
            case .buttonTapped(.bluetoothRegistration):
                state.popupPresent = .bluetoothRegistration
                
            case .buttonTapped(.bluetoothScanStart):
                return .run { send in
                    do {
                        try await obdService.startScan()
                    } catch(let error) {
                        Logger.error(error)
                    }
                }
                
            case let .buttonTapped(.bluetoothConnect(item)):
                Logger.debug("item: \(item)")
                
                return .run { send in
                    let obdInfo = try await obdService.startConnection(address: item.address, timeout: 60)
                    Logger.info("OBDInfo: \(obdInfo)")
                }
                
            case .buttonTapped(.sendMessage):
                Logger.debug("sendMessage: \(state.userCommand)")
                
                return .run { send in
                    let response = try await obdService.requestPIDs([.mode1(.maf)], unit: .metric)
                    Logger.debug("PIds response: \(response)")
                }
                
            case .provider(.registerPublisher):
                return .merge(registerPublisher())
                
            case let .provider(.onDeviceFoundProperty(deviceList)):
                Logger.debug("deviceList: \(deviceList)")
                state.bluetoothItemList = deviceList.toBluetoothItemList()
                
            case .anyAction(.logClear):
                state.obdLog = [""]
            
            default :
                break
            }
            return .none
        }
    }
}

extension ContentFeature {
    private func registerPublisher() -> [Effect<ContentFeature.Action>] {
        var effects : [Effect<ContentFeature.Action>] = .init()
        
        effects.append(Effect<ContentFeature.Action>
            .publisher {
                obdService.onDeviceFoundProperty
                    .map { deviceList in
                        Action.provider(.onDeviceFoundProperty(deviceList))
                    }
            }
        )
        
        return effects
    }
}


extension ContentFeature {
    enum PopupPresent {
        case bluetoothRegistration
    }
}
