//
//  MainFeature+Function.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/19/24.
//

import Foundation
import ComposableArchitecture

extension MainFeature {
    func viewTransitionReducer() -> some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .viewTransition(.onAppear):
                
                return .run { send in
                    await send(.provider(.registerPublisher))
                }
                
            case .viewTransition(.popupDismiss):
                state.bluetoothItemList = .init()
                state.statusItem.bluetoothConnectPresent = false
            default:
                break
            }
            
            return .none
        }
    }
    
    func buttonTappedReducer() -> some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .buttonTapped(.bluetoothRegistration):
                state.statusItem.bluetoothConnectPresent = true
                
            case .buttonTapped(.bluetoothScanStart):
                return .run { send in
                    await obdService.startScan()
                }
                
            case let .buttonTapped(.bluetoothConnect(item)):
                Logger.debug("item: \(item)")
                
                return .run { send in
                    await send(.viewTransition(.loadingOn))
                    await obdService.stopScan()
                    await obdService.stopConnection()
                    
                    do {
                        let obdInfo = try await obdService.startConnection(address: item.address, timeout: 10)
                        await send(.provider(.supportedPID(obdInfo)))
                        try await Task.sleep(for: .seconds(1))
                        await send(.viewTransition(.loadingOff))
                    } catch(let error) {
                        await send(.anyAction(.errorHandling(error)))
                    }
                }
                .throttle(id: ID.throttle, for: 1, scheduler: DispatchQueue.main, latest: true)
                
            case .buttonTapped(.obd2Reset):
                Logger.info("OBD2 Reset")
                state.obdLog = .init(log: [])
                
                return .run { send in
                    await send(.viewTransition(.loadingOn))
                    let obdInfo = try await obdService.reConnection()
                    await send(.provider(.supportedPID(obdInfo)))
                }
                .throttle(id: ID.throttle, for: 1, scheduler: DispatchQueue.main, latest: true)
                
            case .buttonTapped(.bluetoothDisconnect):
                Logger.debug("OBD2 Disconnect")
                state.statusItem.bluetoothConnect = false
                
                return .run { send in
                    await obdService.stopConnection()
                }
                
            case .buttonTapped(.sendMessage):
                state.statusItem.sendLoading = true
                
                return .run { [typeOfCommand = state.commandType] send in
                    try await Task.sleep(for: .seconds(1.5))
                    if typeOfCommand == .AT {
                        await send(.provider(.requestAT))
                    } else {
                        await send(.provider(.requestPID))
                    }
                }
                .throttle(id: ID.throttle, for: 1, scheduler: DispatchQueue.main, latest: true)
                
            case .buttonTapped(.supportedPIDs):
                #if DEBUG
                Logger.debug(state.obdInfo.supportedPIDsToString)
                #endif
                state.statusItem.supportedPIDsCheckPresnet = true
                
            case .buttonTapped(.logClear):
                state.obdLog = .init(log: [""])
                
            default:
                break
            }
            
            return .none
        }
    }
    
    func providerReducer() -> some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .provider(.requestAT):
                let splitCommand = splitByAT(&state, state.userCommand)
                state.statusItem.sendLoading = false

                return .run { send in
                    for command in splitCommand {
                        do {
                            try await obdService.sendATCommand(at: command)
                        } catch { }
                        
                        await send(.anyAction(.addLogSeperate))
                    }
                }
                
            case .provider(.requestPID):
                let commands = splitByPid(&state, state.userCommand)
                Logger.debug("userCommand - \(commands)")
                state.statusItem.sendLoading = false
                
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
                state.statusItem.bluetoothConnect = true
                state.statusItem.bluetoothConnectPresent = false
                
                return .run { send in
                    await send(.viewTransition(.loadingOff))
                    try await obdService.stopScan()
                }
                
            case let .provider(.onDisConnectDeviceProperty(device)), let .provider(.onConnectFailedDeviceProperty(device)):
                Logger.debug("OBD2 disconnected ⛑️")
                initBluetoothConnectInformation(&state, isLogInit: true)
                state.obdLog.append("🚫 OBD2 disconnected - Device Name: \(device.name), Device Address: \(device.address), Time : \(Date())")
                
                return .run { send in
                    await obdService.initsendingMessage()
                    await obdService.stopConnection()
                    await send(.viewTransition(.loadingOff))
                }
            default:
                break
            }
            
            return .none
        }
    }
    
    func anyActionReducer() -> some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .binding(\.commandType):
                Logger.info(state.commandType.name)
                
            case .anyAction(.addLogSeperate):
                state.obdLog.append("")
                
            case let .anyAction(.addLogRes(response)):
                response.forEach { (key, items) in
                    state.obdLog.append("Parse Response: [\(key.properties.description)] \(items.value) \(items.unit.symbol)")
                }
                
            case .anyAction(.errorHandling(_)):
                initBluetoothConnectInformation(&state)
                state.obdLog.append("🚫 OBD2 Connet Error: Please try reconnecting.")
                
                return .run { send in
                    await obdService.initsendingMessage()
                    try await obdService.stopScan()
                    await obdService.stopConnection()
                    await send(.viewTransition(.loadingOff))
                }
            default:
                break
            }
            
            return .none
        }
    }
    
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
    private func initBluetoothConnectInformation(_ state : inout MainFeature.State, isLogInit : Bool = false) {
        if isLogInit {
            state.obdLog = .init(log: [])
        }
        
        state.bluetoothItemList = .init()
        state.statusItem.bluetoothConnect = false
        state.statusItem.bluetoothConnectPresent = false
    }
    
    private func splitByAT(_ state : inout MainFeature.State, _ input: String) -> [String] {
        // "A"를 기준으로 나누고 공백을 추가하는 작업
        let modifiedInput = input.replacingOccurrences(of: "A", with: " A")
        
        // 공백으로 나눈 후, 빈 요소를 제거하고 배열로 변환
        let result = modifiedInput.split(separator: " ").map { String($0) }
        
        // PIDs 가 포함되어있을 경우
        let commands : [String] = result.map {
            if let _ = OBDCommand.fromMode(command: String($0))?.properties.command {
                state.obdLog.append("AT[\($0)] is not supported 😭\n")
                return nil
            } else {
                return $0.uppercased()
            }
        }
            .compactMap { $0 }
        
        // 결과 배열을 순회하면서, 각 요소가 A로 시작하지 않으면 이전 요소와 합침
        var finalResult: [String] = []
        for part in commands {
            if let last = finalResult.last, !part.hasPrefix("A") {
                // A로 시작하지 않으면 이전 요소에 붙임
                finalResult[finalResult.count - 1] = last + part
            } else {
                // A로 시작하면 새 요소로 추가
                finalResult.append(part)
            }
        }
        
        return finalResult
    }
    
    private func splitByPid(_ state : inout MainFeature.State, _ input: String) -> [OBDCommand] {
        let splitCommand = input.split(separator: " ")
        let commands : [OBDCommand] = splitCommand.map {
            if let command = OBDCommand.fromMode(command: String($0)) {
                return command
            } else {
                state.obdLog.append("Pid[\($0)] is not supported 😭\n")
                return nil
            }
        }
            .compactMap { $0 }
        
        return commands
    }
}
