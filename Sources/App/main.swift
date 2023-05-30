import Vapor
import TelegramVaporBot

let tgToken: String = ProcessInfo.processInfo.environment["geometrizebot_telegram_api_key"] ?? "NO_TG_TOKEN"

let tgHostname = ProcessInfo.processInfo.environment["geometrizebot_hostname"] ?? "0.0.0.0"

let tgPort: Int = ProcessInfo.processInfo.environment["geometrizebot_port"].flatMap(Int.init) ?? 80

// nil s3Bucket means no debug upload of source images
let s3Bucket: String? = ProcessInfo.processInfo.environment["debug_upload_images_into_s3_bucket"]

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let eventLoop: EventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount * 4)
let app: Application = .init(env, Application.EventLoopGroupProvider.shared(eventLoop))
let TGBOT: TGBotConnection = .init()

defer { app.shutdown() }
try await configure(app)
try app.run()
