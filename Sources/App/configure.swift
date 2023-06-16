import Vapor
import Leaf
import TelegramVaporBot

public func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = tgHostname
    app.http.server.configuration.port = tgPort

    app.routes.defaultMaxBodySize = "10mb"

    // Serves files from `Public/` directory
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // setup Leaf template engine
    // LeafRenderer.Option.caching = .bypass
    app.views.use(.leaf)

    /// set level of debug if you needed
    TGBot.log.logLevel = app.logger.logLevel
    let bot: TGBot = .init(app: app, botId: tgToken)
    await TGBOTCONNECTION.setConnection(try await TGLongPollingConnection(bot: bot))
    try await DefaultBotHandlers.addHandlers(app: app, connection: TGBOTCONNECTION.connection)
    try await TGBOTCONNECTION.connection.start()
    try routes(app)
}
