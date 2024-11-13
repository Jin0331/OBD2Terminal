//
//  MainFeature.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import Foundation
import ComposableArchitecture
import UIKit

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
        
        var sendLoading : Bool = false
        var bluetoothConnectPresent : Bool = false
        var supportedPIDsCheckPresnet : Bool = false
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
        
        case requestPID
        case supportedPID(OBDInfo)
    }
    
    enum AnyAction {
        case addLogSeperate
        case addLogRes([OBDCommand : MeasurementResult])
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
                state.bluetoothConnectPresent = false
                
            case .buttonTapped(.bluetoothRegistration):
                state.bluetoothConnectPresent = true
                
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
                    try await obdService.stopScan()
                    let obdInfo = try await obdService.startConnection(address: item.address, timeout: 60)
                    await send(.provider(.supportedPID(obdInfo)))
                    try await Task.sleep(for: .seconds(1))
                    await send(.viewTransition(.loadingOff))
                }
                
            case .buttonTapped(.obd2Reset):
                Logger.info("OBD2 Reset")
                state.obdLog = .init()
                
                return .run { send in
                    await send(.viewTransition(.loadingOn))
                    let obdInfo = try await obdService.reConnection()
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
                state.sendLoading = true
                return .run { send in
                    try await Task.sleep(for: .seconds(2))
                    await send(.provider(.requestPID))
                }
                .throttle(id: ID.throttle, for: 1, scheduler: DispatchQueue.main, latest: true)
                
            case .buttonTapped(.supportedPIDs):
                #if DEBUG
                Logger.debug(state.obdInfo.supportedPIDsToString)
                #endif
                state.supportedPIDsCheckPresnet = true
                
            case .buttonTapped(.logClear):
                state.obdLog = [""]
                
            case .buttonTapped(.logShared):
                break
                
            case .provider(.requestPID):
                let splitCommand = state.userCommand.split(separator: " ")
                let commands : [OBDCommand] = splitCommand.map {
                    if let command = OBDCommand.from(command: String($0)) {
                        return command
                    } else {
                        state.obdLog.append("Pid[\($0)] is not supported 😭\n")
                        return nil
                    }
                }
                    .compactMap { $0 }
                
                Logger.debug("userCommand - \(commands)")
                state.sendLoading = false
                
                return .run { send in
                    for command in commands {
                        do {
                            let response = try await obdService.requestPIDs([command], unit: .metric)
                            await send(.anyAction(.addLogRes(response)))
                        } catch { }
                        
                        await send(.anyAction(.addLogSeperate))
                    }
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
                state.bluetoothConnectPresent = false
                
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
                                
            case .anyAction(.addLogSeperate):
                state.obdLog.append(contentsOf: [""])
                
            case let .anyAction(.addLogRes(response)):
                response.forEach { (key, items) in
                    state.obdLog.append("Parse Response: [\(key.properties.description)] \(items.value) \(items.unit.symbol)")
                }
                
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
