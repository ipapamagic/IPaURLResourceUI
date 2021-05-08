//
//  IPaURLResourceUIHelper.swift
//  IPaURLResourceUI
//
//  Created by IPa Chen on 2021/5/3.
//

import Foundation
import Combine
extension IPaURLResourceUIResult {
    public var responseData:Data? {
        switch self {
        case .success(let (_,data)):
            return data
        case .failure(_):
            return nil
        }
    }
    public func jsonData<T>() -> T? {
        self.responseData?.jsonData as? T
    }
}

@available(iOS 13.0, *)

extension URLSession.DataTaskPublisher {
    public func tryGoodResponse() -> Publishers.TryMap<Self, Output> {
        self.tryResponse(Set(arrayLiteral: 200),handle:{return $0})
    }
    public func tryGoodResponse<T>(_ handle: @escaping  ((Output) throws -> T)) -> Publishers.TryMap<Self, T> {
        self.tryResponse(Set(arrayLiteral: 200),handle:handle)
    }
   
    public func tryResponse<T>(_ whiteStatusCodes:Set<Int>,handle: @escaping ((URLSession.DataTaskPublisher.Output) throws -> T)) -> Publishers.TryMap<URLSession.DataTaskPublisher, T> {
        self.tryMap({
            value in
            guard let httpResponse = value.response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            guard whiteStatusCodes.contains(httpResponse.statusCode) else {
                let code = URLError.Code(rawValue: httpResponse.statusCode)
                throw URLError(code)
            }
            
            return try handle(value)
        })
    }
    public func tryGoodResponseJson<T>(_ type:T.Type) -> Publishers.TryMap<Self, T?> {
        self.tryGoodResponse { value in
            return value.data.jsonData as? T
        }
    }
    public func tryGoodResponseJsonDecodable<T:Decodable>(_ type:T.Type) -> Publishers.Decode<Publishers.TryMap<Self, JSONDecoder.Input>, T, JSONDecoder> {
        self.tryGoodResponse({
            value in
            return value.data
        }).decode(type: type, decoder: JSONDecoder())
    }
}
