import Vapor
import TelegramVaporBot

public func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 80
    let tgApi: String = ProcessInfo.processInfo.environment["geometrizebot_telegram_api_key"] ?? "NO_API_KEY"
    /// set level of debug if you needed
    print(tgApi)
    TGBot.log.logLevel = app.logger.logLevel
    let bot: TGBot = .init(app: app, botId: tgApi)
    await TGBOT.setConnection(try await TGLongPollingConnection(bot: bot))
    await DefaultBotHandlers.addHandlers(app: app, connection: TGBOT.connection)
    try await TGBOT.connection.start()
    try routes(app)
}
