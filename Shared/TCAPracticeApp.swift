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
  let webservice: Webservice
  init() {
    self.webservice = Webservice.live
  }
  
  var body: some Scene {
    WindowGroup {
      MainView(
        store: Store(
          initialState: AppState.initial,
          reducer: appReducer,
          environment: AppEnvironment.live(
            webService: self.webservice)
        )
      )
    }
  }
}

public struct StoreInUserDefault: Codable {
   let number: Int
   let string: String
 }

public struct CatFavoriteStore{
  public let valueSUD = "StoreInUserDefaultKey"
  public let storeInUserDefault: (StoreInUserDefault, String) -> ()
  public let readFromUserDefault: (String) -> StoreInUserDefault?
}
