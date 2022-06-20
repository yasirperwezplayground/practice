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

//Issue in test multi platfrom app in Xcode
///https://stackoverflow.com/questions/71973705/why-cant-i-test-a-basic-multiplatform-app-with-xcode

final class FavoriteCatListTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
  
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
  
  
  
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
