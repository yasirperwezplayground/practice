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
  var id: Int?
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
    self.init(id: id.flatMap{ Int($0) }, image: cat)
  }
}

enum CatFavoriteViewAction: Equatable {
  case fetchFavoriteCats
  case fetchFavoriteCatsResponse(Result<[FavoriteCat], CatApiError>)
  case removeFromFavorite(FavoriteCat)
  case favCatRemoved(FavoriteCat)
  case catDetailsViewAction(CatDetailsViewAction)
  case none
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

/*
 let catsListViewReducer =
 Reducer<CatsListViewState, CatsListViewAction, AppEnvironment> {
   state, action, environment in
   print("RDDDD catsListViewReducer \(action)")
   switch action {
   case .fetchCats:
     return environment.getCats(state.currentPage)
       .receive(on: environment.mainQueue)
       .catchToEffect(CatsListViewAction.fetchedCats)
     
   case .fetchedCats(.success(let cats)):
     state.cats.append(contentsOf: cats)
     print("Error in \(state.cats.count)")
     return .none
   case .fetchedCats(.failure):
     print("Error in fetching")
     return .none
   case .catDetailsViewAction:
     return .none
   }
 }
 */

let favoriteViewreducer = Reducer<CatFavoriteViewState, CatFavoriteViewAction, AppEnvironment> {
  state, action, environment in
//  print("RDDDD favoriteViewreducer \(action)")
  
  switch action {
  case .fetchFavoriteCats:
    return  environment.getFavCats()
      .receive(on: environment.mainQueue)
      .catchToEffect(CatFavoriteViewAction.fetchFavoriteCatsResponse)
    
  case .fetchFavoriteCatsResponse(.success(let cats)):
    print("\(cats)")
    state.favoriteCats = Set(cats)
    return .none
    
  case .fetchFavoriteCatsResponse(.failure(let error)):
    print("\(error)")
    return .none
    
  case .removeFromFavorite(let favCat):
    guard let id = favCat.id else  { return .none }
    return environment.removeFromFav(String(id))
      .receive(on: environment.mainQueue)
      .catchToEffect{ result -> CatFavoriteViewAction in
        switch result {
        case .success(let repsonse):
          print("\(repsonse.message ?? "")")
          
          return .favCatRemoved(favCat)
        case .failure(let error):
          return .none
        }
      }
    
  case .favCatRemoved(let favCat):
    state.favoriteCats.remove(favCat)
    return .none
    
  case .catDetailsViewAction:
    return Effect.none
  case .none:
    return .none
  }
}


struct FavCatView: View {
  let cat: FavoriteCat
  let removeAction: (FavoriteCat) -> Void
  
  var body: some View {
    VStack {
      cat.image.map(CatView.init)
      Button("Remove from Fav",
             action: {
        removeAction(cat)
      })
    }
  }
}

struct FavCatListView: View {
  let store: Store<CatFavoriteViewState, CatFavoriteViewAction>
  var body: some View {
    
      ScrollView {
        WithViewStore(self.store) { viewStore in
          let cats = Array<FavoriteCat>(viewStore.favoriteCats)
          let _ = print("FavCatListView \(cats)")
          LazyVStack {
            ForEach(cats) { cat in
              NavigationLink(
                destination: {
                  CatDetailsView(
                    cat: viewStore.favoriteCats.findFirst(cat.image?.id)
                    ?? FavoriteCat(from: cat.image!),
                    store: self.store.scope(
                      state: { $0.favoriteCats },
                      action: CatFavoriteViewAction.catDetailsViewAction
                    )
                  )
                },
                label: {
                  FavCatView(
                    cat: cat) { favCat in
                      viewStore.send(.removeFromFavorite(favCat))
                    }
                }
              )
            }
          }
          .task {
            viewStore.send(.fetchFavoriteCats)
          }
        }
      }
  }
}
