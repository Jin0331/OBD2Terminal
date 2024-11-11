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
        var obdInfo : OBDInfo = .init()
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
        case onConnectEcuProperty
        case onConnectFailedDeviceProperty(BluetoothDevice)
        case onDisConnectDeviceProperty(BluetoothDevice)
        
        case requestPID
    }
    
    enum AnyAction {
        case logClear
        case addLogSeperate
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
                
            case .buttonTapped(.bluetoothDisconnect):
                Logger.debug("OBD2 Disconnect")
                state.bluetoothConnect = false
                
                return .run { send in
                    obdService.stopConnection()
                }
                
            case .buttonTapped(.sendMessage):
                Logger.debug("sendMessage: \(state.userCommand)")
                
                return .run { send in
                    await send(.provider(.requestPID))
                }
                .throttle(id: ID.throttle, for: 1.2, scheduler: DispatchQueue.main, latest: true)
                
            case .provider(.requestPID):
                return .run { send in
                    do {
                        let response = try await obdService.requestPIDs([.mode1(.intakeTemp)], unit: .metric)
                        Logger.debug("PIds response: \(response)")
                    } catch { }
                    
                    await send(.anyAction(.addLogSeperate))
                }
                
            case .provider(.registerPublisher):
                return .merge(registerPublisher())
                
            case let .provider(.onDeviceFoundProperty(deviceList)):
                Logger.debug("deviceList: \(deviceList)")
                state.bluetoothItemList = deviceList.toBluetoothItemList()
                
            case .provider(.onConnectEcuProperty):
                Logger.debug("ECU Connected 🌱")
                state.obdLog.append("ECU Connected 🌱\n")
                state.bluetoothConnect = true
                
                return .run { send in
                    try await obdService.stopScan()
                }
                
            case let .provider(.onDisConnectDeviceProperty(device)), let .provider(.onConnectFailedDeviceProperty(device)):
                Logger.debug("OBD2 disconnected ⛑️")
                state.obdLog.append("OBD2 disconnected - Device Name: \(device.name), Device Address: \(device.address) ⛑️")
                
                return .run { send in
                    obdService.stopConnection()
                }
                
            case .anyAction(.logClear):
                state.obdLog = [""]
                
            case .anyAction(.addLogSeperate):
                state.obdLog.append(contentsOf: [""])
            
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
        
        effects.append(Effect<ContentFeature.Action>
            .publisher {
                obdService.onConnectEcuProperty
                    .map { device in
                        Action.provider(.onConnectEcuProperty)
                    }
            }
        )
        
        effects.append(Effect<ContentFeature.Action>
            .publisher {
                obdService.onDisConnectDeviceProperty
                    .map { device in
                        Action.provider(.onDisConnectDeviceProperty(device))
                    }
            }
        )
        
        effects.append(Effect<ContentFeature.Action>
            .publisher {
                obdService.onConnectFailedDeviceProperty
                    .map { device in
                        Action.provider(.onConnectFailedDeviceProperty(device))
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
    
    enum ID: Hashable {
        case debounce, throttle
    }
}
