//
//  Decoder.swift
//  TCAPractice
//
//  Created by Mohammad Yasir Perwez on 15.03.22.
//

import Foundation
import Combine
import ComposableArchitecture

extension Publisher where Output == Data, Failure == URLError {
  public func apiDecode<A: Decodable>(
    as type: A.Type,
    file: StaticString = #file,
    line: UInt = #line
  ) -> Effect<A, CatApiError> {
    self
      .mapError { _ in CatApiError.noInternet }
      .flatMap { data -> AnyPublisher<A, CatApiError> in
        do {
          return try Just(
            JSONDecoder.holiduDecoder.decode(
              A.self,
              from: data
            )
          )
          .setFailureType(
            to: CatApiError.self
          )
          .eraseToAnyPublisher()
        } catch {          
          return Fail(error: CatApiError.decodingError).eraseToAnyPublisher()
        }
      }
      .eraseToEffect()
  }
}
