//
//  OnlineUsersManager.swift
//  App
//
//  Created by 杨学思 on 2018/6/1.
//

import Vapor
import JWT

public class OnlineUserManager {

    static public let `default` = {
        return OnlineUserManager.init()
    }()

    private init() { }

    private var users: Set<ComputerUserInfo> = []
    private var connections: [ComputerUserInfo : WebSocket] = [:]
    private var tokens: [ComputerUserInfo : Data] = [:]

    public func register(user: ComputerUserInfo, connection: WebSocket) -> Bool {
        if users.insert(user).inserted {
            connections[user] = connection
            return true
        } else if let _ = connections[user] {
            connections[user] = connection
            return true
        } else {
            return false
        }
    }

    public func isHavingConnection(with user: String) -> Bool {
        if let connection = connection(with: user) {
            return !connection.isClosed
        } else {
            return false
        }
    }

    public func connection(with user: String) -> WebSocket? {
        return connections.filter{ $0.key.name == user }.first?.value
    }

    public var onlineUsers: [String] {
        return OnlineUserManager.default.users.filter{ OnlineUserManager.default.isHavingConnection(with: $0.name) }.map{ $0.name }
    }

    public func validate(user: ComputerUserInfo) -> Bool {
        return OnlineUserManager.default.users.filter{ OnlineUserManager.default.isHavingConnection(with: $0.name) }.contains(user)
    }

    public func generateToken(for user: ComputerUserInfo) -> Data? {
        let payload = ClientPayload(user: user)
        var jwt = JWT(payload: payload)
        if let token = try? jwt.sign(using: signer) {
            tokens[user] = token
            return token
        }
        return nil
    }

    public func verifyToken(for payload: Data) -> String? {
        let jwt = try? JWT<ClientPayload>.init(from: payload, verifiedUsing: signer)
        do {
            try jwt?.payload.verify()
            return jwt?.payload.user
        } catch {
            return nil
        }
    }

    public func sendCommand(to user: String, with command: ComputerCommand) {
        let connection = self.connection(with: user)
        connection?.send(command)
    }

}
fileprivate let tokenKey = "mcfans.tech TOKEN"
fileprivate let signer = JWTSigner.hs256(key: tokenKey.convertToData())

public struct ClientPayload: JWTPayload {
    var claimer = ExpirationClaim(value: Date().addingTimeInterval(48*3600))
    public func verify() throws {
        try claimer.verify()
    }
    var user: String
    init(user: ComputerUserInfo) {
        self.user = user.name
    }
}


