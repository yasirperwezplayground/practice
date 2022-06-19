//
//  CatDetailsView.swift
//  TCAPractice
//
//  Created by Mohammad Yasir Perwez on 09.02.22.
//

import ComposableArchitecture
import SwiftUI
import UIKit
import Combine

struct FavEditResponse: Decodable {
  var id: Int?
  var message: String?
}

enum CatDetailsViewAction: Equatable {
  case favoriteToggled(Bool, FavoriteCat)
  case favAdded(FavoriteCat)
  case favRemoved(FavoriteCat)
  case none
}

struct CatDetailsEnvironment {
}

let catDetailsViewReducer = Reducer<Set<FavoriteCat>, CatDetailsViewAction, AppEnvironment> {
  state, action, environment in
  switch action {
  case .favoriteToggled(let isFav, let cat):
    
    let savedDic = readFromUserDefault(forKey: "Test1")
    print("MMMMMM \(savedDic)")
    
    if isFav {
      guard let catId = cat.id else { return .none }
      return environment.removeFromFav(String(catId))
        .receive(on: environment.mainQueue)
        .catchToEffect { _ in
          // check if removal is right else show error
          CatDetailsViewAction.favRemoved(cat)
        }
    } else {
      guard let catId = cat.image?.id else { return .none }
      
      /// to transform a  Publisher<String, CatApiError> to Effect<String, Never>
      /// I have used catchToEffect( with a closure to tranform both of result cases to CatDetailsViewAction
      /// need to watchout for a simple way to tranforms them
      ///
      return environment.addToFav(catId)
        .receive(on: environment.mainQueue)
        .map { $0.id } // map return => Publisher<String, CatApiError>
        .catchToEffect { result -> CatDetailsViewAction in // (Result<String, CatApiError>) -> T
          switch result {
          case .success(let id):
            var favCat = cat
            favCat.id = id
            return .favAdded(favCat)
          case.failure:
            return .none
          }
        } // Effect<CatDetailsViewAction, Never>
    }
  case .favAdded(let cat):
    state.insert(cat)
    return .none
  case .favRemoved(let cat):
    state.remove(cat)
    return .none
  case .none:
    return .none
  }
}
  .debug()


struct CatDetailsView: View {
  let cat: FavoriteCat
  let store: Store<Set<FavoriteCat>,CatDetailsViewAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack(spacing: 16) {
        AsyncImage(
          url: URL(
            string: self.cat.image?.url ?? ""
          ),
          content: { image in
            image.resizable()
              .aspectRatio(contentMode: .fit)
          },
          placeholder: { ProgressView() }
        ).cornerRadius(16.0)
        Button(
          action: {
            viewStore.send(
              .favoriteToggled(
                viewStore.state.findFirst(
                  self.cat.image?.id) != nil,
                self.cat
              )
            )
          } ,
          label: {
            Image(systemName: "heart.circle")
              .foregroundColor(
                viewStore.state.findFirst(self.cat.image?.id) != nil ? .red : .gray
              )
          }
        )
      }.padding()
    }
  }
}




//struct CatDetails: Decodable {
//  let id: String?
//  let url: String?
//  let subId: String?
//  let createdId: String?
//
//  enum CodingKeys: String, CodingKey {
//    case subId = "sub_id"
//    case createdId = "created_id"
//    case id
//    case url
//  }
//}

//struct CatsDetailsViewState {
//  var cat: Cat
//  var isFavorite: Bool
//}


/*
 {
 "id": 2146538,
 "message": "SUCCESS"
 }
 */

//struct CatDatailsViewState {
//  let catonScreen: FavoriteCat
//  let favorites: Set<FavoriteCat>
//}
