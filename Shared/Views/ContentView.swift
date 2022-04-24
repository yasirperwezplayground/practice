
import ComposableArchitecture
import SwiftUI
import UIKit
import Combine

struct MainView: View {
  let store: Store<AppState, AppAction>
  var body: some View {
    NavigationView {
      VStack(spacing: 8) {
        NavigationLink(
          destination: {
            CatsListView(
              store: self.store.scope(
                state: { $0.catsListViewState },
                action: AppAction.catsListActions)
            )
          },
          label: { Text("Cats")}
        )
        NavigationLink(
          destination: {
            FavCatListView(
              store: self.store.scope(
                state: { $0.catFavoriteViewState },
                action: AppAction.favoriteAction
              )
            )
          },
          label: { Text("Fav Cats")}
        )
      }
    }
    .navigationTitle("Cats")
  }
}






