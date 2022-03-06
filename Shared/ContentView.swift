
import ComposableArchitecture
import SwiftUI
import UIKit
import Combine

/// save favorite cats locally as well
/// Cats api key
/// dc34ebc3-5565-417d-9685-a2b285896efc
/// https://api.thecatapi.com/v1/images/search


enum CatApiError: Error, Equatable {
  case noInternet
  case failedWithErrorCode(Int)
  case faildWithMessage(String)
  case unknown
}

enum ParseError: Error, Equatable {
  case failedToParse(String)
  case unknown
}

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

/// Custom case path . But this approach does  not looks good.
/// We should try to arrage the state in a other way.
///  the problem here was that catDetailsViewAction is a case of both enum.
///  It is a cse of shared action same enum is nested in two different hirarcy
///  We can compose the cats details reducer and Catlist reduce and we can also compose the favcatlist reducer with catdetails reduce
///
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


let appReducer = Reducer.combine(
  
  catDetailsViewReducer
    .pullback(
      state: \AppState.favoriteCats,
      action:  datailsCatPath,
      environment: { $0 }
    ),
  catsListViewReducer
    .pullback(
      state: \AppState.catsListViewState,
      action: /AppAction.catsListActions,
      environment: { $0 }
    ),
  favoriteViewreducer
    .pullback(
      state: \AppState.catFavoriteViewState,
      action: /AppAction.favoriteAction,
      environment: { $0 }
    )
)//.debug()


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

//MARK: - MainView
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


//===============   Side Effect Starts   =======================/

///https://api.thecatapi.com/v1/images/search

enum RequestType {
  case authenticated
  case open
}


class RequestBuilder {
  static let baseUrl = URL(string: "https://api.thecatapi.com")
  
  static func getFavCatRequest() -> Request<[FavoriteCat]> {
    Request<[FavoriteCat]>.init(
      path: "/v1/favourites",
      queryItems: [
        URLQueryItem(name: "limit", value: "\(100)")
      ],
      method: .get,
      isAuthenticated: false
    )
  }
  
  static func getFavCatRequest(id: String) -> Request<[FavoriteCat]> {
    Request<[FavoriteCat]>.init(
      path: "/v1/favourites",
      queryItems: [
        URLQueryItem(name: "limit", value: "\(100)")
      ],
      method: .get,
      isAuthenticated: false
    )
  }
  
  
  static func addToFavRequest(id: String) -> Request<FavEditResponse> {
    Request<FavEditResponse>.init(
      path: "/v1/favourites",
      queryItems: [],
      method: .post,
      isAuthenticated: false,
      postData: ["image_id": id]
    )
  }
  
  
  static func getCatsRequest(page: Int) -> Request<[Cat]> {
    Request<[Cat]>.init(
      path:"/v1/images/search",
      queryItems: [
        URLQueryItem(name: "page", value: "\(page)"),
        URLQueryItem(name: "limit", value: "\(100)")
      ],
      method: .get,
      isAuthenticated: false
    )
    
  }
  
  static func deleteFavCatRequest(id: String) -> Request<FavEditResponse> {
    Request<FavEditResponse>.init(
      path: "/v1/favourites/\(id)",
      queryItems: [],
      method: .delete,
      isAuthenticated: true
    )
  }
  
  
  func urlRequest(path: String,
                  queryItems: [URLQueryItem],
                  method: HTTPMethod,
                  isAuthenticated: Bool,
                  postData: [String: Any]?
  ) -> URLRequest? {
    
    var components = URLComponents.init(url: RequestBuilder.baseUrl!, resolvingAgainstBaseURL: false)
    components?.path = path
    components?.queryItems = queryItems
    
    guard let url = components?.url else { return nil }
    
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.allHTTPHeaderFields = [
      "x-api-key": "dc34ebc3-5565-417d-9685-a2b285896efc",
      "Content-Type": "application/json"
    ]
    if let postData = postData {
      request.httpBody = try? JSONSerialization.data(
        withJSONObject: postData,
        options: [])
    }
    return request
  }
}

enum HTTPMethod: String {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case patch = "PATCH"
  case delete = "DELETE"
}

struct Request<T: Decodable> {
  public typealias Model = T
  
  public init(
    path: String,
    queryItems: [URLQueryItem],
    method: HTTPMethod = .get,
    isAuthenticated: Bool = false,
    postData: [String: Any]? = nil
  ) {
    self.path = path
    self.queryItems = queryItems
    self.method = method
    self.isAuthenticated = isAuthenticated
    self.postData = postData
  }
  
  let path: String
  let queryItems: [URLQueryItem]
  let method: HTTPMethod
  let isAuthenticated: Bool
  let postData: [String: Any]?
}


typealias Networking = (URLRequest) ->
AnyPublisher<(data: Data, response: URLResponse), Error>
typealias Parse<Model> = (Data) -> AnyPublisher<Model, Error>
typealias RequestToUrlReqeust = (String, [URLQueryItem], HTTPMethod, Bool, [String: Any]?) -> URLRequest?

extension URLSession {
  func erasedDataTaskPublisher(
    for request: URLRequest
  ) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
    dataTaskPublisher(for: request)
      .mapError { $0 }
      .eraseToAnyPublisher()
  }
}

class Webservice {
  let networking: Networking
  var requestBuilder: RequestToUrlReqeust?
  
  public init(
    networking: @escaping Networking
  ) {
    self.networking = networking
  }
  public func fetch<Model: Decodable>(
    request: Request<Model>
  ) -> AnyPublisher<Model, CatApiError> {
    // Convert the Request<Model> into URL request
    guard let requestBuilder = self.requestBuilder,
          let request = requestBuilder(
            request.path,
            request.queryItems,
            request.method,
            request.isAuthenticated,
            request.postData
          ) else {
            return Result.Publisher(
              CatApiError.unknown
            ).eraseToAnyPublisher()
          }
    
    // Get response from server
    return networking(request)
      .map{ $0.data }
      .decode()
      .mapError{ _ in CatApiError.unknown }
      .eraseToAnyPublisher()
  }
}

extension Publisher where Output == Data {
  func decode<T: Decodable>(
    as type: T.Type = T.self,
    using decoder: JSONDecoder = .holiduDecoder
  ) -> Publishers.Decode<Self, T, JSONDecoder> {
    // we can handle error here if we want
    decode(type: type, decoder: decoder)
  }
}


extension JSONDecoder {
  static let holiduDecoder: JSONDecoder = {
    JSONDecoder()
  }()
}

extension RequestBuilder {
  func urlRequest<Model>(for request: Request<Model>) -> URLRequest? {
    
    var components = URLComponents.init(url: RequestBuilder.baseUrl!, resolvingAgainstBaseURL: false)
    components?.path = request.path
    components?.queryItems = request.queryItems
    
    guard let url = components?.url else { return nil }
    
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = [
      "x-api-key": "dc34ebc3-5565-417d-9685-a2b285896efc"
    ]
    return request
  }
}



//struct Response<T: Decodable> {
//  public typealias Model = T
//
//  let request: Request<Model>
//  let data: Data?
//  let urlResponse: URLResponse?
//  let error: CatApiError?
//}



