import Vapor
import TelegramVaporBot

let tgToken: String = ProcessInfo.processInfo.environment["geometrizebot_telegram_api_key"] ?? "NO_TG_TOKEN"

let tgHostname = ProcessInfo.processInfo.environment["geometrizebot_hostname"] ?? "0.0.0.0"

let tgPort: Int = ProcessInfo.processInfo.environment["geometrizebot_port"].flatMap(Int.init) ?? 80

let tgCertPEM: String = ProcessInfo.processInfo.environment["geometrizebot_cert_pem"] ?? "NO_CERT_PEM"

let tgKeyPEM: String = ProcessInfo.processInfo.environment["geometrizebot_key_pem"] ?? "NO_KEY_PEM"

// nil s3Bucket means no debug upload of source images
let s3Bucket: String? = ProcessInfo.processInfo.environment["debug_upload_images_into_s3_bucket"]

// This extension is temporary and can be removed once Vapor gets this support.
// This is from project created with `vapor new hello -n`.
private extension Vapor.Application {
    static let baseExecutionQueue = DispatchQueue(label: "vapor.codes.entrypoint")

    func runFromAsyncMainEntrypoint() async throws {
        try await withCheckedThrowingContinuation { continuation in
            Vapor.Application.baseExecutionQueue.async { [self] in
                do {
                    try self.run()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let eventLoopGroup: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount * 4)
let app: Application = Application(
    env,
    Application.EventLoopGroupProvider.shared(eventLoopGroup)
)
app.logger.logLevel = .trace
let TGBOTCONNECTION: TGBotConnection = TGBotConnection()

defer { app.shutdown() }

do {
    try await configure(app)
} catch {
    app.logger.report(error: error)
    throw error
}
try await app.runFromAsyncMainEntrypoint()
