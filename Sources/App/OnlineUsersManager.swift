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
    fileprivate var tokens: [ComputerUserInfo : String] = [:]

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
            tokens[user] = payload.controllerID.value
            return token
        }
        return nil
    }

    public func verifyToken(for payload: Data) -> String? {
        let jwt = try? JWT<ClientPayload>.init(from: payload, verifiedUsing: signer)
        do {
            try jwt?.payload.verify()
            return jwt?.payload.sub.value
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
    var exp = ExpirationClaim(value: Date().addingTimeInterval(48*3600))
    var sub: SubjectClaim
    var controllerID: SubjectClaim

    public func verify() throws {
        try exp.verify()
        if !OnlineUserManager.default.isHavingConnection(with: sub.value) {
            throw TokenVerifyError.lossConnection
        }
        let (_,value) = OnlineUserManager.default.tokens.filter { (key,value) -> Bool in
            return key.name == sub.value
        }.first!
        if value != controllerID.value {
            throw TokenVerifyError.haveUser
        }
    }

    init(user: ComputerUserInfo) {
        sub = SubjectClaim(value: user.name)
        controllerID = SubjectClaim(value: UUID().uuidString)
    }
}

enum TokenVerifyError: Error {
    case lossConnection
    case haveUser
}

