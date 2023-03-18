//
//  Requests.swift
//  TCAPractice
//
//  Created by Mohammad Yasir Perwez on 06.03.22.
//

import Foundation

extension RequestBuilder {
  
  static func getFavCatRequest() -> Request<[FavoriteCat]> {
    Request<[FavoriteCat]>.init(
      data: RequestData(
        path: "/v1/favourites",
        queryItems: [
          URLQueryItem(name: "limit", value: "\(100)")
        ],
        method: .get
      )
    )
  }
  
  static func addToFavRequest(id: String) -> Request<FavEditResponse> {
    Request<FavEditResponse>.init(
      data: RequestData(
        path: "/v1/favourites",
        queryItems: [],
        method: .post,
        postData: ["image_id": id]
      )
    )
  }
  
  
  static func getCatsRequest(page: Int) -> Request<[Cat]> {
    Request<[Cat]>.init(
      data: RequestData(
        path:"/v1/images/search",
        queryItems: [
          URLQueryItem(name: "page", value: "\(page)"),
          URLQueryItem(name: "limit", value: "\(100)")
        ],
        method: .get
      )
    )
  }
  
  static func deleteFavCatRequest(id: String) -> Request<FavEditResponse> {
    Request<FavEditResponse>.init(
      data: RequestData(
        path: "/v1/favourites/\(id)",
        queryItems: [],
        method: .delete
      )
    )
  }
}

