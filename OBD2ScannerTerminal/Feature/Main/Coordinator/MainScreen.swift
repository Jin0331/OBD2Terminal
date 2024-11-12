//
//  MainScreen.swift
//  OBD2ScannerTerminal
//
//  Created by Namuplanet on 11/12/24.
//

import Foundation
import ComposableArchitecture

@Reducer(state:.equatable)
enum MainScreen {
    case main(MainFeature)
}
