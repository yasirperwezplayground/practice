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
  let requestBuilder: RequestBuilder
  
  init() {
    self.requestBuilder = RequestBuilder()
    self.webservice = Webservice(
      networking: URLSession.shared.erasedDataTaskPublisher(for:)
    )
    self.webservice.requestBuilder = self.requestBuilder.urlRequest(path:queryItems:method:isAuthenticated:postData:)
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
