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
        var bluetoothItemList : BluetoothItemList = .init()
        var bluetoothConnect : Bool = false
        var userCommand : String = .init()
        var obdInfo : OBDInfo = .init()
        @Shared(Environment.SharedInMemoryType.obdLog.keys) var obdLog : [String] = ["OBD2 Terminal Start..."]
        
        var popupPresent : PopupPresent?
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
        
        case requestPID
        case supportedPID(OBDInfo)
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
                    await send(.viewTransition(.loadingOn))
                    let obdInfo = try await obdService.startConnection(address: item.address, timeout: 60)
                    await send(.provider(.supportedPID(obdInfo)))
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
                
            case .buttonTapped(.supportedPIDs):
                Logger.debug(state.obdInfo.supportedPIDsToString)
                state.popupPresent = .supportedPIDsCheck
                
            case .provider(.requestPID):
                return .run { send in
                    do {
                        try await obdService.requestPIDs([.mode1(.intakeTemp)], unit: .metric)
                    } catch { }
                    
                    await send(.anyAction(.addLogSeperate))
                }
                
            case let .provider(.supportedPID(OBDInfo)):
                state.obdInfo = OBDInfo
                
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
                    await send(.viewTransition(.loadingOff))
                    try await obdService.stopScan()
                }
                
            case let .provider(.onDisConnectDeviceProperty(device)), let .provider(.onConnectFailedDeviceProperty(device)):
                Logger.debug("OBD2 disconnected ⛑️")
                state.obdLog.append("🚫 OBD2 disconnected - Device Name: \(device.name), Device Address: \(device.address), Time : \(Date())")
                
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

extension MainFeature {
    private func registerPublisher() -> [Effect<MainFeature.Action>] {
        var effects : [Effect<MainFeature.Action>] = .init()
        
        effects.append(Effect<MainFeature.Action>
            .publisher {
                obdService.onDeviceFoundProperty
                    .map { deviceList in
                        Action.provider(.onDeviceFoundProperty(deviceList))
                    }
            }
        )
        
        effects.append(Effect<MainFeature.Action>
            .publisher {
                obdService.onConnectEcuProperty
                    .map { device in
                        Action.provider(.onConnectEcuProperty)
                    }
            }
        )
        
        effects.append(Effect<MainFeature.Action>
            .publisher {
                obdService.onDisConnectDeviceProperty
                    .map { device in
                        Action.provider(.onDisConnectDeviceProperty(device))
                    }
            }
        )
        
        effects.append(Effect<MainFeature.Action>
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


extension MainFeature {
    enum PopupPresent {
        case bluetoothRegistration
        case supportedPIDsCheck
    }
    
    enum ID: Hashable {
        case debounce, throttle
    }
}
