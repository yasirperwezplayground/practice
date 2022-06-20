import ComposableArchitecture
import SwiftUI
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
          label: {
            Text("All Cates")
              .font(.title3)
          }
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
          label: { Text("My Favorites")}
        )
      }.navigationTitle("Cuties")
    }
  }
}






