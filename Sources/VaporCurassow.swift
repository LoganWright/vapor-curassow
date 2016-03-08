//
//  VaporCurassow.swift
//  Vapor+Curassow
//
//  Created by Logan Wright on 3/8/16.
//  Copyright © 2016 loganwright. All rights reserved.
//

import Nest
import Inquiline
import Curassow
import Commander

import Vapor

// MARK: Helpers

private final class BytesPayload : PayloadType {
    var bytes: [UInt8]
    
    init<T: SequenceType where T.Generator.Element == UInt8>(bytes: T) {
        self.bytes = [UInt8](bytes)
    }
    
    func next() -> [UInt8]? {
        if bytes.isEmpty {
            return nil
        }
        
        return [bytes.removeFirst()]
    }
}


// MARK: Request Bridge

extension PayloadType {
    mutating func collect(length: Int) -> [UInt8] {
        var buffer: [UInt8] = []
        
        while buffer.count < length, let bytes = next() {
            buffer += bytes
        }
        
        return buffer
    }
}

extension Vapor.Request {
    // TODO: Verify that we're converting appropriately, not everything here is 1:1
    convenience init(_ req: Nest.RequestType) {
        let method = Vapor.Request.Method(rawValue: req.method.uppercaseString) ?? .Unknown
        
        let path = req.path
        
        var headers: [String : String] = [:]
        req.headers.forEach { key, val in
            headers[key] = val
        }
        
        let address = "unknown"
        
        var body: [UInt8] = []
        if let lengthString = headers["Content-Length"], let length = Int(lengthString) where length > 0 {
            var mutable = req
            body += mutable.body?.collect(length) ?? []
        }
        
        self.init(method: method, path: path, address: address, headers: headers, body: body)
    }
}

// MARK: Response Bridge

extension Vapor.Response.ContentType {
    var statusLine: String {
        switch self {
        case .Json:
            return "application/json"
        case .Text:
            fallthrough
        case .Html:
            return "text/html"
        case .None:
            return "no content"
        case let .Other(description):
            return description
        }
    }
}

extension Vapor.Response: Nest.ResponseType {
    public var statusLine: String {
        return contentType.statusLine
    }
    
    public var headers: [Nest.Header] {
        let vaporHeaders: [String : String] = self.headers
        return vaporHeaders.map { $0 }
    }
    
    public var body: PayloadType? {
        get {
            return BytesPayload(bytes: data)
        }
        set {
            var mutable = newValue
            var bod: [UInt8] = []
            while let next = mutable?.next() {
                bod += next
            }
            data = bod
        }
    }
}

// MARK: CurrassowServer

public final class CurassowServer: ServerDriver {
    
    // MARK: ServerDriver
    
    public var delegate: ServerDriverDelegate? = nil
    
    public func boot(port port: Int) throws {
        if port != 80 {
            print("Currassow does not support port argument in code, use `--bind 0.0.0.0:\(port)`")
        }
        Curassow.serve(handle)
    }
    
    public func halt() {
        print("Curassow must be halted from terminal")
    }
    
    // MARK: Curassow Server Handler
    
    private func handle(req: RequestType) -> ResponseType {
        guard let dele = delegate else {
            return Inquiline.Response(.ExpectationFailed, contentType: "text/html", content: "No Router Available")
        }
        
        let vaporRequest = Vapor.Request(req)
        return dele.serverDriverDidReceiveRequest(vaporRequest)
    }
}

// MARK: CurassowVapor Provider

public final class Provider: Vapor.Provider {
    public static func boot(application: Vapor.Application) {
        application.server = CurassowServer()
    }
}
