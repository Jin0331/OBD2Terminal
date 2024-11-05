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
        
    }
    
    enum ViewTransition {
        case onAppear
    }

    enum Provider {
        case registerPublisher
        case onDeviceFoundProperty(BluetoothDeviceList)
    }
    
    enum AnyAction {

    }
    
    @Dependency(\.obd2Gateway) var obd2Gateway
    
    var body : some ReducerOf<Self> {
        
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            
            case .viewTransition(.onAppear):
                obd2Gateway.setGateway()
                
                return .run { send in
                    await send(.provider(.registerPublisher))
                }
            
            case .provider(.registerPublisher):
                return .merge(registerPublisher())
                
            case let .provider(.onDeviceFoundProperty(deviceList)):
                Logger.debug(deviceList)
                
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
                obd2Gateway.onDeviceFoundProperty
                    .map { deviceList in
                        Action.provider(.onDeviceFoundProperty(deviceList))
                    }
            }
        )
        
        return effects
    }
}
