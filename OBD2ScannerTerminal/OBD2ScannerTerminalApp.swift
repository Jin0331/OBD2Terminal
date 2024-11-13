//
//  OBD2ScannerTerminalApp.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/4/24.
//

import SwiftUI
import ComposableArchitecture

@main
struct OBD2ScannerTerminalApp: App {
    @State var isSplashView = true
    
    init() {
        Logger.configurations()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isSplashView {
                    LaunchScreenView()
                        .ignoresSafeArea()
                        .transition(.opacity.animation(.easeIn))
                        .zIndex(1)
                    
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                isSplashView = false
                            }
                            
                            UIApplication.shared.isIdleTimerDisabled = true /// 앱 자동 잠금 비활성화
                        }
                } else {
                    MainCoordinatorView(store: Store(initialState: .initialState, reducer: {
                        MainCoordinator()
                    }))
                }
            }
        }
    }
}

struct LaunchScreenView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let controller = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()!
        return controller
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}
