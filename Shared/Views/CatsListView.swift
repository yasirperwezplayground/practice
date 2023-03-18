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
    dump(cats)
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
//    ZStack {
//      RoundedRectangle(cornerRadius: 12)
//        .stroke(
//          Color(.sRGB, red: 150/255, green: 150/255, blue: 150/255, opacity: 0.8),
//          lineWidth: 1
//        )
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
        ).cornerRadius(12)
        
        Text(self.cat.id ?? "")
      }.padding(8)
      
      .background(Color.white)
      .cornerRadius(12)
      .shadow(color: .black.opacity(0.5), radius: 12)
      .padding()
    }
      
//  }
}

struct CatsListView: View {
  let store: Store<CatsListViewState, CatsListViewAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      GeometryReader { reader in
      ScrollView {
        VStack(alignment: .center, spacing: 16) {
            if viewStore.cats.isEmpty {
              HStack(alignment: .center) {
                ProgressView {
                  Text("Loading cats")
                }
              }.frame(width: reader.size.width, height: reader.size.height)
          } else {
            LazyVStack(spacing: 32) {
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
        }
          .padding(16)
      }
    }.navigationTitle("All Cats")
      .task {
        viewStore.send(.fetchCats)
      }
    }
  }
}


