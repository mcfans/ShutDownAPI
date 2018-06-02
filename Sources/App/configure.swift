import Vapor
/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    /// Register providers first

    /// Register routes to the router

    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    let wss = NIOWebSocketServer.default()
    wss.get("register") { (ws, req) in
        ws.onText({ (inWs, text) in
            let data = text.convertToData()
            if let info = try? JSONDecoder().decode(ComputerUserInfo.self, from: data) {
                if OnlineUserManager.default.register(user: info, connection: ws) {
                    inWs.send("Registered")
                } else {
                    inWs.send("User already exists Please login in")
                }
            } else {
                inWs.send("Can't parse data")
            }
        })
        ws.onBinary({ (inWs, data) in

        })
    }
    services.register(wss, as: WebSocketServer.self)
    /// Register middleware
//    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
//    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
//    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
//    services.register(middlewares)


}
