//
//  CatDetailsViewTest.swift
//  TCAPracticeUnitTests
//
//  Created by Mohammad Yasir Perwez on 19.06.22.
//

import XCTest
import ComposableArchitecture
import SnapshotTesting
import SwiftUI
@testable import TCAPractice


class CatDetailsViewTest: XCTestCase {
  
  func testCatDetailsViewSnapShot() {
    
    let favoriteCat = FavoriteCat(
      id: 1234,
      image: Cat(
        id: "12345",
        url: "https://cdn2.thecatapi.com/images/_LwjLMlVA.jpg"
      )
    )
    
    let store = Store(
      initialState: Set([favoriteCat]),
      reducer: catDetailsViewReducer,
      environment: AppEnvironment.mock()
    )
    let viewStore = ViewStore(store)
    
    let catDetailsView = CatDetailsView(
      cat: favoriteCat,
      store: store
    )

    isRecording = true
    
    let expectation = self.expectation(description: "wait")
    DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
      expectation.fulfill()
    }
    self.wait(for: [expectation], timeout: 30)
    
    
    let vc = UIHostingController(rootView: catDetailsView)
    vc.view.frame = UIScreen.main.bounds
    // should be favorite
    assertSnapshot(matching: vc, as: .image)
    viewStore.send(.favRemoved(favoriteCat))
    // should not be favorite
    let vc1 = UIHostingController(rootView: CatDetailsView(
      cat: favoriteCat,
      store: store
    )
)
    vc1.view.frame = UIScreen.main.bounds
    assertSnapshot(matching: vc1, as: .image)
    //shoud be favorite again
    let vc2 = UIHostingController(rootView: CatDetailsView(
      cat: favoriteCat,
      store: store
    )
)
    vc2.view.frame = UIScreen.main.bounds
    viewStore.send(.favAdded(favoriteCat))
    assertSnapshot(matching: vc2, as: .image)
  }

  func testStringSnapshot() {
    let string = "Test me"
    assertSnapshot(matching: string, as: .lines)
  }
  
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
