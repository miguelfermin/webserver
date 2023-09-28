//
//  Action.swift
//
//
//  Created by Miguel Fermin on 8/31/23.
//

import NIOCore
import NIOHTTP1
import Hummingbird

public struct Request<T: Decodable> {
    public let model: T
    public var context: [String: Any] = [:]
    public let queryItems: [String: String]
    public let params: [String: String]
}

public struct RequestVoid {
    public var context: [String: Any] = [:]
    public let queryItems: [String: String]
    public let params: [String: String]
}

func actionHandler<I: Decodable, O: Encodable>(_ fn: @escaping (Request<I>) async throws -> O) -> (HBRequest) async throws -> O {
    return { request in
        var params: [String: String] = [:]
        var queryItems: [String: String] = [:]
        for (key, value) in request.uri.queryParameters { queryItems["\(key)"] = "\(value)" }
        for (key, value) in request.parameters { params["\(key)"] = "\(value)" }
        print("params: \(params)")
        print("queryItems: \(queryItems)")
        
        let model = try request.decode(as: I.self)
        let input = Request(model: model, queryItems: queryItems, params: params)
        let output: O = try await fn(input)
        return output
    }
}

func actionHandlerVoid<O: Encodable>(_ fn: @escaping (RequestVoid) async throws -> O) -> (HBRequest) async throws -> O {
    return { request in
        var params: [String: String] = [:]
        var queryItems: [String: String] = [:]
        for (key, value) in request.uri.queryParameters { queryItems["\(key)"] = "\(value)" }
        for (key, value) in request.parameters { params["\(key)"] = "\(value)" }
        print("params: \(params)")
        print("queryItems: \(queryItems)")
        
        let input = RequestVoid(context: [:], queryItems: queryItems, params: params)
        let output: O = try await fn(input)
        return output
    }
}

public struct ServerError: Error, HBHTTPResponseError {
    /// status code for the error
    public let status: HTTPResponseStatus
    /// any addiitional headers required
    public let headers: HTTPHeaders
    /// error payload, assumed to be a string
    public let body: String?

    /// Initialize HTTPError
    /// - Parameters:
    ///   - status: HTTP status
    ///   - code: Error domain code.
    ///   - message: Associated message
    public init(_ status: HTTPResponseStatus, code: Int, message: String) {
        self.status = status
        self.headers = ["content-type": "application/json"]
        self.body = """
{"code": "\(code)", "message": "\(message)"}
"""
    }

    /// Get body of error as ByteBuffer
    public func body(allocator: ByteBufferAllocator) -> ByteBuffer? {
        return self.body.map { allocator.buffer(string: $0) }
    }
}
