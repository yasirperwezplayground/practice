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
    storeInUserDefault(
      sud: StoreInUserDefault(
        number: 8,
        string: "Yasir"),
      forKey: "Test1"
    )
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

struct StoreInUserDefault: Codable {
   let number: Int
   let string: String
 }

 let valueSUD = "StoreInUserDefaultKey"

 func storeInUserDefault(sud: StoreInUserDefault, forKey: String) {

   let encoder = JSONEncoder()
   encoder.outputFormatting = [.prettyPrinted]
   encoder.dataEncodingStrategy = .base64
   guard let jsonData = try? encoder.encode(sud) else { return }
   let jsonString = String(bytes: jsonData, encoding: .utf8)

   UserDefaults.standard.set(jsonString, forKey: forKey)
   UserDefaults.standard.synchronize()
 }

 func readFromUserDefault(forKey: String) -> StoreInUserDefault? {
   guard let jsonString = UserDefaults.standard.string(forKey: forKey),
         let jsonData = jsonString.data(using: .utf8),
         let value = try? JSONDecoder().decode(StoreInUserDefault.self, from: jsonData) else {
     return nil
   }
   return value
 }
 
