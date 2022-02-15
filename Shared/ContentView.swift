
import ComposableArchitecture
import SwiftUI
import UIKit
import Combine


/// save favorite cats locally as well
/// Cats api key
/// dc34ebc3-5565-417d-9685-a2b285896efc
/// https://api.thecatapi.com/v1/images/search


struct CatApiError: Error, Equatable {}

struct AppState: Equatable {
  var cats: [Cat]
  var currentPage: Int
  
  var favoriteCats: Set<FavoriteCat>
  
  public init() {
    self.cats = []
    self.currentPage = 0
    self.favoriteCats = []
  }
}

enum AppAction: Equatable {
  case catsListActions(CatsListViewAction)
  case favoriteAction(CatFavoriteViewAction)
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
extension AppEnvironment {
  static let live = AppEnvironment(
    getCats: getCats(page:),
    getFavCats: getFavCatsAPI,
    addToFav: addFavCatsAPI(id:),
    removeFromFav: deleteFavCatsAPI(id:),
    mainQueue: DispatchQueue.main
  )
}

let appReducer = Reducer.combine(
  catsListViewReducer.pullback(
    state: \AppState.catsListViewState,
    action: /AppAction.catsListActions,
    environment: { $0 }
  ),
  favoriteViewreducer.pullback(
    state: \AppState.catFavoriteViewState,
    action: /AppAction.favoriteAction,
    environment: { $0 }),
  
  catDetailsViewReducer.pullback(
    state: \AppState.favoriteCats,
    action: /AppAction.catsListActions .. CatsListViewAction.catDetailsViewAction,
    environment: { $0 })
)
//
//AppAction.catsListActions.CatsListActions.catDetailsViewAction,

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
            CatFavoriteView(
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








//===============   Side Effect Starts   =======================/

///https://api.thecatapi.com/v1/images/search

func getCatsRequest(page: Int) -> URLRequest? {
  var components = URLComponents()
  components.scheme = "https"
  components.host = "api.thecatapi.com"
  components.path = "/v1/images/search"
  
  components.queryItems = [
    URLQueryItem(name: "page", value: "\(page)"),
    URLQueryItem(name: "limit", value: "\(100)")
  ]
  
  guard let url = components.url else { return nil }
  var request = URLRequest(url: url)
  request.allHTTPHeaderFields = [
    "x-api-key": "dc34ebc3-5565-417d-9685-a2b285896efc"
  ]
  return request
}

func addToFavRequest(id: String) -> URLRequest? {
  var components = URLComponents()
  components.scheme = "https"
  components.host = "api.thecatapi.com"
  components.path = "/v1/favourites"
    
  guard let url = components.url else { return nil }
  var request = URLRequest(url: url)
  request.allHTTPHeaderFields = [
    "x-api-key": "dc34ebc3-5565-417d-9685-a2b285896efc",
    "Content-Type": "application/json"
  ]
  request.httpMethod = "POST"
  let body: [String: Any] = [
    "image_id": id
  ]
  
  request.httpBody = try? JSONSerialization.data(
    withJSONObject: body,
    options: [])
  
  return request
}

func deleteFavRequest(id: String) -> URLRequest? {
  var components = URLComponents()
  components.scheme = "https"
  components.host = "api.thecatapi.com"
  components.path = "/v1/favourites/\(id)"
    
  guard let url = components.url else { return nil }
  var request = URLRequest(url: url)
  request.allHTTPHeaderFields = [
    "x-api-key": "dc34ebc3-5565-417d-9685-a2b285896efc",
    "Content-Type": "application/json"
  ]
  request.httpMethod = "DELETE"
  return request
}

func getFavCatsRequest() -> URLRequest? {
  var components = URLComponents()
  components.scheme = "https"
  components.host = "api.thecatapi.com"
  components.path = "/v1/favourites"
  
  components.queryItems = [
    URLQueryItem(name: "limit", value: "\(100)")
  ]
  
  guard let url = components.url else { return nil }
  var request = URLRequest(url: url)
  request.allHTTPHeaderFields = [
    "x-api-key": "dc34ebc3-5565-417d-9685-a2b285896efc"
  ]
  return request
}

func getCatDetailsRequest() -> URLRequest? {
  var components = URLComponents()
  components.scheme = "https"
  components.host = "api.thecatapi.com"
  components.path = "/v1/favourites"
  
  components.queryItems = [
    URLQueryItem(name: "limit", value: "\(100)")
  ]
  
  guard let url = components.url else { return nil }
  var request = URLRequest(url: url)
  request.allHTTPHeaderFields = [
    "x-api-key": "dc34ebc3-5565-417d-9685-a2b285896efc"
  ]
  return request
}


func getFavCatsAPI() -> Effect<[FavoriteCat], CatApiError> {
  let request = getFavCatsRequest()
  return URLSession.shared.dataTaskPublisher(for: request!)
    .map { $0.data }
    .decode(type: [FavoriteCat].self, decoder: JSONDecoder())
    .eraseToAnyPublisher()
    .mapError { _ in CatApiError() }
    .eraseToEffect()
}

func addFavCatsAPI(id: String) -> Effect<FavEditResponse, Never> {
  let request = addToFavRequest(id: id)
  return URLSession.shared.dataTaskPublisher(for: request!)
    .map {
      print("\(String(data: $0.data ?? Data(), encoding: .utf8))")
      print("\($0.response)")
      return $0.data
    }
    .decode(type: FavEditResponse.self, decoder: JSONDecoder())
    .mapError { _ in return Never.self }
    .eraseToEffect()
}

func deleteFavCatsAPI(id: String) -> Effect<FavEditResponse, CatApiError> {
  let request = deleteFavRequest(id: id)
  return URLSession.shared.dataTaskPublisher(for: request!)
    .map { $0.data }
    .decode(type: FavEditResponse.self, decoder: JSONDecoder())
    .eraseToAnyPublisher()
    .mapError { _ in CatApiError() }
    .eraseToEffect()
}


func getCats(page: Int) -> Effect<[Cat], CatApiError> {
  let request = getCatsRequest(page: page)
  return URLSession.shared.dataTaskPublisher(for: request!)
    .map { $0.data }
    .decode(type: [Cat].self, decoder: JSONDecoder())
    .eraseToAnyPublisher()
    .mapError { _ in CatApiError() }
    .eraseToEffect()
}


//===============   Side Effect Starts   =======================/
