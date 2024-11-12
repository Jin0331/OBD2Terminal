//
//  MainCoordinator.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/11/24.
//

import SwiftUI
import ComposableArchitecture
import TCACoordinators

struct MainCoordinatorView : View {
    @State var store : StoreOf<MainCoordinator>
    
    var body : some View {
        WithPerceptionTracking {
            ZStack {
                if store.showLoadingIndicator {
                    LoadingView(showLoadingIndicator: $store.showLoadingIndicator, value: 0.2)
                        .transition(.opacity.animation(.easeIn))
                        .zIndex(1)
                }
                
                TCARouter(store.scope(state: \.routes, action: \.router)) { screen in
                    switch screen.case {
                    case let .main(store):
                        MainView(store: store)
                            .zIndex(0)
                    }
                }
            }
        }
    }
}


@Reducer
struct MainCoordinator {
    @ObservableState
    struct State : Equatable {
        static var initialState = State(routes: [.root(.main(.init()), embedInNavigationView: true)])
        var routes: IdentifiedArrayOf<Route<MainScreen.State>>
        
        var showLoadingIndicator : Bool = false
    }
    
    enum Action : BindableAction {
        case binding(BindingAction<State>)
        case router(IdentifiedRouterActionOf<MainScreen>)
    }
    
    var body : some ReducerOf<Self> {
        
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
                
            case .router(.routeAction(id: .main, action: .main(.viewTransition(.loadingOn)))):
                state.showLoadingIndicator = true
                
            case .router(.routeAction(id: .main, action: .main(.viewTransition(.loadingOff)))):
                state.showLoadingIndicator = false
                
            default :
                break
            }
            return .none
        }
        .forEachRoute(\.routes, action: \.router)
    }
}
