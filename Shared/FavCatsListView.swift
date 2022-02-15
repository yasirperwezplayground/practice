//
//  FavCatsListView.swift
//  TCAPractice
//
//  Created by Mohammad Yasir Perwez on 09.02.22.
//

import ComposableArchitecture
import SwiftUI
import UIKit
import Combine


//FIXME: make it conform to codeable so that it can be seriealised to disk
struct FavoriteCat: Decodable, Equatable, Identifiable, Hashable {
  var id: String?
  let image: Cat?
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(image)
  }
}

extension Set where Element == FavoriteCat {
  func findFirst(_ catId: String?) -> FavoriteCat? {
    return self.first { $0.image?.id == catId }
  }
}

extension FavoriteCat {
  init(from cat: Cat, id: String? = nil) {
    self.init(id: id, image: cat)
  }
}

enum CatFavoriteViewAction: Equatable {
  case fetchFavoriteCats
  case fetchFavoriteCatsResponse(Result<[FavoriteCat], CatApiError>)
  case removeFromFavorite(String)
}

struct CatFavoriteViewState: Equatable {
  ///FIXME:- When should happen when a view contains some logic state and logic logic. With TCA what I understand till now is that an screen works on a view of a certain part of the global state. Reducer for that view runs the side effect  and will make change to this view of the state.
  ///What should happend when there are some local state  that only local view needs,
  ///should it be managed by @State and any dependency can be fed to it in the constructor (effects etc)
  ///or Global state should contain these local variablesw
  /// or should they have a local view model to put all the logic so that view is just a dump view without any logic in it.
  /// l will prefer the last approach
  
  var favoriteCats: Set<FavoriteCat>
}

let favoriteViewreducer = Reducer<CatFavoriteViewState, CatFavoriteViewAction, AppEnvironment> {
  state, action, environment in
  switch(action){
  case .fetchFavoriteCats:
    return  environment.getFavCats()
      .receive(on: environment.mainQueue)
      .catchToEffect(CatFavoriteViewAction.fetchFavoriteCatsResponse)
  case .fetchFavoriteCatsResponse(.success(let cats)):
    state.favoriteCats = Set(cats)
    return .none
  case .fetchFavoriteCatsResponse(.failure(let error)):
    return .none
  case .removeFromFavorite(let catId):
    return .none
  }
  
}


struct FavCatView: View {
  let cat: FavoriteCat
  let removeAction: (String) -> Void
  
  var body: some View {
    VStack {
      cat.image.map(CatView.init)
      Button("Remove from Fav",
             action: {
        cat.id.map(removeAction)
      })
    }
  }
}

struct CatFavoriteView: View {
  let store: Store<CatFavoriteViewState, CatFavoriteViewAction>
  var body: some View {
    NavigationView {
      ScrollView {
        WithViewStore(self.store) { viewStore in
          let cats = Array<FavoriteCat>(viewStore.favoriteCats)
          LazyVStack {
            ForEach(cats) { cat in
              FavCatView(
                cat: cat) { id in
                  viewStore.send(.removeFromFavorite(id))
                }
            }
          }
          .task {
            viewStore.send(.fetchFavoriteCats)
          }
        }
      }
    }
  }
}
