import Vapor
import JWT
/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    struct Users: Content {
        var users: [String]
    }
    router.get("users") { req -> Users in
        return Users(users: OnlineUserManager.default.onlineUsers)
    }

    //    FIXME: Already login problem
    router.post(ComputerUserInfo.self, at: "login") { (req,info) -> LoginStatus in
        if OnlineUserManager.default.validate(user: info) {
            if let data = OnlineUserManager.default.generateToken(for: info) {
                return .success(data)
            }
            return .failure
        }
        return .failure
    }

    router.post(RunCommandMessage.self, at: "run") { (req,message) -> String in
        if let user = OnlineUserManager.default.verifyToken(for: message.payload) {
            if OnlineUserManager.default.isHavingConnection(with: user) {
                OnlineUserManager.default.sendCommand(to: user, with: message.command)
                return "Sent"
            }
            return "Lost Connection With Computer \(user)"
        }
        return "Token expired"
    }
}
