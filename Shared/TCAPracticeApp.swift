//
//  TCAPracticeApp.swift
//  Shared
//
//  Created by Mohammad Yasir Perwez on 07.02.22.
//

import SwiftUI
import ComposableArchitecture

@main
struct TCAPracticeApp: App {
    var body: some Scene {
        WindowGroup {
          MainView(
            store: Store(
              initialState: AppState.initial,
              reducer: appReducer,
              environment: AppEnvironment.live
            )
          )
        }
    }
}
