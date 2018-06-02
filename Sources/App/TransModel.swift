//
//  TransModel.swift
//  App
//
//  Created by 杨学思 on 2018/6/1.
//

import Vapor

public struct ComputerUserInfo: Codable,Hashable {
    var name: String
    var encryptedPassWord: String
}

extension ComputerUserInfo: RequestDecodable {
    public static func decode(from req: Request) throws -> EventLoopFuture<ComputerUserInfo> {
        return try req.content.decode(ComputerUserInfo.self)
    }
}

public struct RunCommandMessage: Codable {
    var command: ComputerCommand
    var payload: Data
}
public typealias ComputerCommand = String
extension RunCommandMessage: RequestDecodable{
    public static func decode(from req: Request) throws -> EventLoopFuture<RunCommandMessage> {
        return try req.content.decode(RunCommandMessage.self)
    }
}

public enum LoginStatus {
    case success(Data)
    case failure
    case exists
}

extension LoginStatus: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.failure) {
            self = .failure
        } else if container.contains(.exists) {
            self = .exists
        } else {
            let payload = try container.decode(Data.self, forKey: .success)
            self = .success(payload)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .success(let payload):
            try container.encode(payload, forKey: .success)
        case .failure:
            try container.encodeNil(forKey: .failure)
        case .exists:
            try container.encodeNil(forKey: .exists)
        }
    }
    
    enum CodingKeys: CodingKey {
        case success
        case failure
        case exists
    }
}

extension LoginStatus: ResponseCodable {
    public static func decode(from res: Response, for req: Request) throws -> EventLoopFuture<LoginStatus> {
        return try res.content.decode(LoginStatus.self)
    }

    public func encode(for req: Request) throws -> EventLoopFuture<Response> {
        let data = try JSONEncoder().encode(self)
        let res = Response.init(http: .init(body: data), using: req.sharedContainer)
        return req.eventLoop.newSucceededFuture(result: res)
    }

}
