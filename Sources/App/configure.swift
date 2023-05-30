import Vapor
import TelegramVaporBot

public func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = tgHostname
    app.http.server.configuration.port = tgPort
    /// set level of debug if you needed
    TGBot.log.logLevel = app.logger.logLevel
    let bot: TGBot = .init(app: app, botId: tgToken)
    await TGBOT.setConnection(try await TGLongPollingConnection(bot: bot))
    try await DefaultBotHandlers.addHandlers(app: app, connection: TGBOT.connection)
    try await TGBOT.connection.start()
    try routes(app)
}
