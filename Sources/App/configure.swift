import Vapor
import NIOSSL
import Leaf
import TelegramVaporBot

public func configure(_ app: Application) async throws {
    app.http.server.configuration.hostname = tgHostname
    app.http.server.configuration.port = tgPort

    app.http.server.configuration.responseCompression = .enabled

    // Enable TLS.
    let certPEM = tgCertPEM.utf8CString.map(UInt8.init(bitPattern:))
    let keyPEM = tgKeyPEM.utf8CString.map(UInt8.init(bitPattern:))
    app.http.server.configuration.tlsConfiguration = .makeServerConfiguration(
        certificateChain: try NIOSSLCertificate.fromPEMBytes(certPEM).map { .certificate($0) },
        privateKey: .privateKey(try NIOSSLPrivateKey(bytes: keyPEM, format: .pem))
    )

    app.routes.defaultMaxBodySize = "10mb"

    // Serves files from `Public/` directory
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // setup Leaf template engine
    // LeafRenderer.Option.caching = .bypass
    app.views.use(.leaf)

    // set level of debug if you needed
    TGBot.log.logLevel = app.logger.logLevel
    let bot: TGBot = .init(app: app, botId: tgToken)
    await TGBOTCONNECTION.setConnection(try await TGLongPollingConnection(bot: bot))
    try await DefaultBotHandlers.addHandlers(app: app, connection: TGBOTCONNECTION.connection)
    try await TGBOTCONNECTION.connection.start()
    try routes(app)
}
