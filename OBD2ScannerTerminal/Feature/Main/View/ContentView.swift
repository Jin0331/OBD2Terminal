//
//  ContentView.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    
    @State var store : StoreOf<ContentFeature>
    
    var body: some View {
        WithPerceptionTracking {
            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Hello, world!")
            }
            .padding()
            .onAppear {
                store.send(.viewTransition(.onAppear))
            }
        }
    }
}

#Preview {
    ContentView(store: Store(initialState: ContentFeature.State(), reducer: {
        ContentFeature()
    }))
}
