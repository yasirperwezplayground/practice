//
//  CatsListView.swift
//  TCAPractice
//
//  Created by Mohammad Yasir Perwez on 09.02.22.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct Cat: Decodable, Equatable, Identifiable, Hashable {
  let id: String?
  let url: String?
  
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(url)
  }
}

struct CatsListViewState: Equatable {
  var cats: [Cat]
  var favoriteCats: Set<FavoriteCat>
  var currentPage: Int
}

enum CatsListViewAction: Equatable {
  case fetchCats
  case fetchedCats(Result<[Cat], CatApiError>)
  case catDetailsViewAction(CatDetailsViewAction)
}

let catsListViewReducerEnriched = Reducer.combine(
  catsListViewReducer,
  catDetailsViewReducer.pullback(
    state: \CatsListViewState.favoriteCats,
    action: /CatsListViewAction.catDetailsViewAction,
    environment: { $0 }
  )
)


let catsListViewReducer =
Reducer<CatsListViewState, CatsListViewAction, AppEnvironment> {
  state, action, environment in
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
///A cell in CatsListView
struct CatView: View {
  var cat: Cat
  
  var body: some View {
    VStack {
      AsyncImage(
        url: URL(
          string: self.cat.url ?? ""
        ),
        content: { image in
          image.resizable()
            .aspectRatio(
              contentMode: .fit
            )
        },
        placeholder: {
          ProgressView()
        }
      )
      Text(self.cat.id ?? "")
    }
  }
}

struct CatsListView: View {
  let store: Store<CatsListViewState, CatsListViewAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      ScrollView{
        VStack(spacing: 8) {
          if viewStore.cats.isEmpty {
            Text("Loading")
            ProgressView()
          } else {
            LazyVStack {
              ForEach(viewStore.cats) { cat in
                NavigationLink(
                  destination: {
                    CatDetailsView(
                      cat: viewStore.favoriteCats.findFirst(cat.id) ?? FavoriteCat(from: cat),
                      store: self.store.scope(
                        state: { $0.favoriteCats },
                        action: CatsListViewAction.catDetailsViewAction
                      )
                    )
                  },
                  label: {
                    CatView(cat: cat)
                    
                  }
                )
              }
            }
          }
        }.padding(16)
      }
      .task {
        viewStore.send(.fetchCats)
      }
    }
  }
}


