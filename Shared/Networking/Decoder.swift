//
//  Decoder.swift
//  TCAPractice
//
//  Created by Mohammad Yasir Perwez on 15.03.22.
//

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

//public struct CatApiError: Codable, Error, Equatable, LocalizedError {
//  public let errorDump: String
//  public let file: String
//  public let line: UInt
//  public let message: String
//
//  public init(
//    error: Error,
//    file: StaticString = #fileID,
//    line: UInt = #line
//  ) {
//    var string = ""
//    dump(error, to: &string)
//    self.errorDump = string
//    self.file = String(describing: file)
//    self.line = line
//    self.message = error.localizedDescription
//  }
//
//  public var errorDescription: String? {
//    self.message
//  }
//}
