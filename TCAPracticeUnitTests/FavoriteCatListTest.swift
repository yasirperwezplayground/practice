//
//  FavoriteCatListTest.swift
//  Tests iOS
//
//  Created by Mohammad Yasir Perwez on 19.06.22.
//

import XCTest
import SwiftUI
import SnapshotTesting
@testable import TCAPractice
import ComposableArchitecture


//Issue in test multi platfrom app in Xcode
///https://stackoverflow.com/questions/71973705/why-cant-i-test-a-basic-multiplatform-app-with-xcode

final class FavoriteCatListTest: XCTestCase {
  
  func testFavoriteReducer() {
    
    let cat = FavoriteCat(
      id: 2,
      image: Cat(
        id: "1",
        url: "www.example.com"
      )
    )
    
    var state = CatFavoriteViewState(
      favoriteCats: Set(
        [cat]
      )
    )
    
    myFavoriteCatsListViewReducer(
      &state,
      CatFavoriteViewAction.favCatRemoved(cat),
      AppEnvironment.mock()
    )
    
    XCTAssertTrue(state.favoriteCats.isEmpty)
  }
  
  
  func testWithTestStore() {
    
    let cat = FavoriteCat(
      id: 2,
      image: Cat(
        id: "1",
        url: "www.example.com"
      )
    )
    
    let state = CatFavoriteViewState(
      favoriteCats: Set(
        [cat]
      )
    )

    var environment = AppEnvironment.mock()
    environment.mainQueue = .immediate
    environment.getFavCats = {
      return Effect.init(value: [cat])
    }
    let store = TestStore.init(
      initialState: state,
      reducer: myFavoriteCatsListViewReducer,
      environment: environment)
    
    store.send(.fetchFavoriteCats)
    
    store.receive(.fetchFavoriteCatsResponse(.success([cat]))) {
      $0.favoriteCats = [cat]
    }
    
    store.send(.removeFromFavorite(cat))
    
    store.receive(.favCatRemoved(cat)){
      $0.favoriteCats = []
    }
    
    
    
  }
  
}
