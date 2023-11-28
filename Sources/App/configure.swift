import Vapor
import Leaf
import TelegramVaporBot

public func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = tgHostname
    app.http.server.configuration.port = tgPort

    app.http.server.configuration.responseCompression = .enabled

    // Enable TLS.
    // For this configuration to compile you need to add import NIOSSL at the top
    // of your configuration file. You also might need to add NIOSSL as a dependency
    // in your Package.swift file.
    //app.http.server.configuration.tlsConfiguration = .forServer(
    //    certificateChain: NIOSSLCertificate.fromPEMFile("/path/to/cert.pem").map { .certificate($0) },
    //    privateKey: .file("/path/to/key.pem")
    //)

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
