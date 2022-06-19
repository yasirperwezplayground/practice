//
//  Client.swift
//  TCAPractice
//
//  Created by Mohammad Yasir Perwez on 06.03.22.
//

import Foundation
import Combine

//TODO:
/*
- flexiblity in changing the Url session
- adding special hearder to request
- hooking for networking and parsing logs
*/
public enum CatApiError: Error, Equatable {
  case noInternet
  case failedWithErrorCode(Int)
  case faildWithMessage(String)
  case decodingError
  case unknown
}


enum RequestType {
  case authenticated
  case open
}

enum HTTPMethod: String {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case patch = "PATCH"
  case delete = "DELETE"
}

/// Domain request details. Request builder transforms this into URL requests
struct RequestData {
  
  public init(
    path: String,
    queryItems: [URLQueryItem],
    method: HTTPMethod = .get,
    type: RequestType = .open,
    postData: [String: Any]? = nil
  ) {
    self.path = path
    self.queryItems = queryItems
    self.method = method
    self.type = type
    self.postData = postData
  }
  
  let path: String
  let queryItems: [URLQueryItem]
  let method: HTTPMethod
  let type: RequestType
  let postData: [String: Any]?
}

/// Makes the request generic. We need to store the type of requested Domain Model to parse the response DTO in the required domain model.
struct Request<T: Decodable> {
  public typealias Model = T
  
  public init(
    data: RequestData
  ) {
    self.data = data
  }
  
  let data: RequestData
}

/// Shape of the function which takes URLRequest and returns a publisher
typealias Networking = (URLRequest) ->
AnyPublisher<(data: Data, response: URLResponse), Error>



/// Shape of the function which takes RequestData and transforms it to URLRequest
typealias RequestToUrlReqeust = (RequestData) -> URLRequest?

/// Main Tasks
/// * Request => Request.Model
/// * Request => URLRequest => Request.Model
///
//TODO:
/*
 - All networking related error should be logged and monitored in Networking function
 - All decodeing related error should be logged and monitored in decode() function
 - Header enrichment should happen in the RequestToUrlReqeust func i.e it should be part of request builder. There should be a separate func which adds the required header based on the type of request [open|authenticaste]. Do we also need to have separate func to add header for other endpoints like log/analytics?
 */
struct Webservice {
  ///    Dependencies
  let networking: Networking
  var requestBuilder: RequestToUrlReqeust
  
  public init(
    networking: @escaping Networking,
    requestBuilder: @escaping RequestToUrlReqeust
  ) {
    self.networking = networking
    self.requestBuilder = requestBuilder
  }
}

extension Webservice {
  
  public func fetch<Model: Decodable>(
    request: Request<Model>
  ) -> AnyPublisher<Model, CatApiError> {
    
    // Convert the Request<Model> into URL request
    guard let request = self.requestBuilder(
      request.data
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

extension Webservice {
  static let live = Self(
    networking: loggedNetworking(PrintLogger())(URLSession.shared.erasedDataTaskPublisher(for:)) ,
    requestBuilder: RequestBuilder().urlRequest(requestData:)
  )
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
//TODO: push app relate info to Requestbuilder.


extension JSONDecoder {
  static public let holiduDecoder: JSONDecoder = {
    JSONDecoder()
  }()
}
//TODO:
/*
 
 */

class RequestBuilder {
  static let baseUrl = URL(string: "https://api.thecatapi.com")
  
  //TODO: Make highorder function to add Hearder
  func urlRequest(requestData: RequestData) -> URLRequest? {
    
    var components = URLComponents.init(url: RequestBuilder.baseUrl!, resolvingAgainstBaseURL: false)
    components?.path = requestData.path
    components?.queryItems = requestData.queryItems
    
    guard let url = components?.url else { return nil }
    
    var request = URLRequest(url: url)
    request.httpMethod = requestData.method.rawValue
    request.allHTTPHeaderFields = [
      "x-api-key": "dc34ebc3-5565-417d-9685-a2b285896efc",
      "Content-Type": "application/json"
    ]
    if let postData = requestData.postData {
      request.httpBody = try? JSONSerialization.data(
        withJSONObject: postData,
        options: [])
    }
    return request
  }
}


extension URLSession {
  
  /// <#Description#>
  /// - Parameter request: <#request description#>
  /// - Returns: <#description#>
  func erasedDataTaskPublisher(
    for request: URLRequest
  ) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
    dataTaskPublisher(for: request)
      .mapError { $0 }
      .eraseToAnyPublisher()
  }
  
  // Networking with Log
  // this function should do all the logging and monitering job
  // This function should send the log to monitoring server when we have an unexpected response
  // from BE, or in case of timeout etc.
  // SHOULD IT USE A SEPARATE URLSESSION. IMO IT SHOULD BECUASE IT WILL CONSISTANTLY HIT A SEPARATE ENDPOINT
//  /func erasedDataTaskPublisher()
}


protocol Logger {
  func logError(message: String)
}

struct PrintLogger: Logger{
  func logError(message: String) {
    print("Logging \(message)")
  }
}

let loggedNetworking: (Logger) -> (@escaping Networking) -> Networking =
{
  logger in {
    networking in
    { urlRequest in
      logger.logError(message: "Before")
     return  networking(urlRequest).mapError { _ in CatApiError.unknown }
        .eraseToAnyPublisher()
    }
  }
}



//(URLRequest) ->
//AnyPublisher<(data: Data, response: URLResponse), Error>
