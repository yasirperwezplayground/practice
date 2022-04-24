//
//  AppState.swift
//  TCAPractice
//
//  Created by Mohammad Yasir Perwez on 24.04.22.
//

import ComposableArchitecture
import SwiftUI
import UIKit
import Combine

/// save favorite cats locally as well
/// Cats api key
/// dc34ebc3-5565-417d-9685-a2b285896efc
/// https://api.thecatapi.com/v1/images/search

struct AppState: Equatable {
  var cats: [Cat]
  var favoriteCats: Set<FavoriteCat>
  
  var currentPage: Int
  public init() {
    self.cats = []
    self.currentPage = 0
    self.favoriteCats = []
  }
}

enum AppAction: Equatable {
  case catsListActions(CatsListViewAction)
  case favoriteAction(CatFavoriteViewAction)
  case catDetailsViewAction(CatDetailsViewAction)
}

struct AppEnvironment {
  var getCats: (Int) -> Effect<[Cat], CatApiError>
  var getFavCats: () -> Effect<[FavoriteCat], CatApiError>
  var addToFav: (String) -> Effect<FavEditResponse, CatApiError>
  var removeFromFav: (String) -> Effect<FavEditResponse, CatApiError>
  var mainQueue: DispatchQueue
}

extension AppState {
  static var initial = AppState()
}

extension AppState {
  var catsListViewState: CatsListViewState {
    get {
      CatsListViewState(
        cats: self.cats,
        favoriteCats: self.favoriteCats,
        currentPage: self.currentPage
      )
    }
    set {
      self.cats = newValue.cats
      self.currentPage = newValue.currentPage
      self.favoriteCats = newValue.favoriteCats
    }
  }
  
  var catFavoriteViewState: CatFavoriteViewState {
    get {
      CatFavoriteViewState(favoriteCats: self.favoriteCats)
    }
    set {
      self.favoriteCats = newValue.favoriteCats
    }
  }
}

extension AppEnvironment {
  static func live(
    webService: Webservice
  ) -> AppEnvironment {
    return AppEnvironment(
      getCats: { page in
        webService.fetch(
          request: RequestBuilder.getCatsRequest(page: page)
        ).eraseToEffect()
      },
      getFavCats: {
        webService.fetch(
          request: RequestBuilder.getFavCatRequest()
        ).eraseToEffect()
      },
      addToFav: { id in
        webService.fetch(request: RequestBuilder.addToFavRequest(id: id))
          .eraseToEffect()
      },
      removeFromFav: { id in
        webService.fetch(request: RequestBuilder.deleteFavCatRequest(id: id))
          .eraseToEffect()
      },
      mainQueue: DispatchQueue.main
    )
  }
}

/// Custom case path. Was used to read and embed values from CatsListViewAction and CatFavoriteViewAction to get catDetailsViewAction
/// We should try to arrage the state in a other way.
///  the problem here was that catDetailsViewAction is a case of both enum CatsListViewAction CatFavoriteViewAction.
///  It is the case of shared action same enum is nested in two different hirarcy
///  We can compose the cats details reducer and Catlist reduce and we can also compose the favcatlist reducer with catdetails reduce
/// But this approach does  not looks good. So as jaleel suggest we could also combine the CatsListView reduce and CatsDetailsViewReducer and same with FavCatslistViewReducer.
/*
let datailsCatPath =  CasePath.init(
  embed: { catDetailsAction  in
    
    AppAction.favoriteAction(.catDetailsViewAction(catDetailsAction))
  },
  extract: { appAction in
    switch appAction {
    case .catsListActions(.catDetailsViewAction(let local)):
      return local
    case .favoriteAction(.catDetailsViewAction(let local)):
      return local
    default: return nil
    }
  })
 
 */



let appReducer = Reducer.combine(

  catsListViewReducerEnriched
    .pullback(
      state: \AppState.catsListViewState,
      action: /AppAction.catsListActions,
      environment: { $0 }
    ),
  favoriteViewreducerEnriched
    .pullback(
      state: \AppState.catFavoriteViewState,
      action: /AppAction.favoriteAction,
      environment: { $0 }
    )
)



