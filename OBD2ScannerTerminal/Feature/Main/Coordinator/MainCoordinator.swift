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
        TCARouter(store.scope(state: \.routes, action: \.router)) { screen in
            switch screen.case {
            case let .main(store):
                MainView(store: store)
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
    }
    
    enum Action {
        case router(IdentifiedRouterActionOf<MainScreen>)
    }
    
    var body : some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            default :
                break
            }
            return .none
        }
        .forEachRoute(\.routes, action: \.router)
    }
}
