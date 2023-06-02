import Vapor
import TelegramVaporBot
import Geometrize
import JPEG

final class DefaultBotHandlers {

    static func addHandlers(app: Vapor.Application, connection: TGConnectionPrtcl) async throws {
        try await messageHandler(app: app, connection: connection)
        await commandPingHandler(app: app, connection: connection)
        await commandHelpHandler(app: app, connection: connection)
        await commandStartHandler(app: app, connection: connection)
    }

    struct GeometrizingData {
        let messageId: Int
        let image: Image
        let fileUrl: URL
        let originalPhotoWidth: Int
        let originalPhotoHeight: Int
    }

    enum DialogState {
        case waitImageFromUser
        case waitShapeType
        case waitShapeCount
    }

    static var imageDatas: [Int64 /* userId */: GeometrizingData] = [:]

    // Kept between sessions to be reused by user choosing option "As last time"
    static var shapeTypes: [Int64 /* userId */: Set<ShapeType>] = [:]

    // Kept between sessions to be reused by user choosing option "As last time"
    static var shapeCounts: [Int64 /* userId */: Int] = [:]

    typealias Action = (TGUpdate, TGBot) async throws -> DialogState

    static var state = [Int64 /* userId */: DialogState]()

    static var actions: [DialogState: Action] =
        [
            .waitImageFromUser: { update, bot in
                print("waitImageFromUser")
                guard let message = update.message, let userId = message.from?.id, let photoSizes = message.photo else { return .waitImageFromUser }
                let (photoData, filePath) = try await downloadPhoto(bot: bot, tgToken: tgToken, photoSizes: photoSizes, maxHeightAndWidth: 512)
                let fileUrl = URL(fileURLWithPath: filePath)
                let fileNameWithExt = URL(fileURLWithPath: filePath).lastPathComponent
                let fileNameNoExt = fileNameWithExt.dropLast(fileUrl.pathExtension.count + 1)
                if let s3Bucket {
                    do {
                        try await uploadToS3(bucket: s3Bucket, fileName: "\(userId)-\(fileNameWithExt)", data: photoData)
                    } catch {
                        print(error)
                    }
                }
                let image: Image
                switch URL(fileURLWithPath: filePath).pathExtension.lowercased() {
                case "jpg", "jpeg":
                    image = .jpeg(photoData)
                case "png":
                    throw "Processing PNG is not implemented"
                default:
                    throw "Cannot process file \(filePath)"
                }
                let (originalPhotoWidth, originalPhotoHeight) = photoSizes.map { ($0.width, $0.height) }.max { $0.0 < $1.0 }!
                imageDatas[userId] = GeometrizingData(
                    messageId: message.messageId,
                    image: image,
                    fileUrl: URL(fileURLWithPath: filePath),
                    originalPhotoWidth: originalPhotoWidth,
                    originalPhotoHeight: originalPhotoHeight
                )
                let keyboard = TGReplyKeyboardMarkup(
                    keyboard:
                        [[TGKeyboardButton(text: "Rectangles"),
                          TGKeyboardButton(text: "Rotated rectangles")
                         ],
                         [TGKeyboardButton(text: "Triangles")],
                         [TGKeyboardButton(text: "Circles"),
                          TGKeyboardButton(text: "Ellipses"),
                          TGKeyboardButton(text: "Rotated Ellipses")
                         ],
                         [TGKeyboardButton(text: "Lines"),
                          TGKeyboardButton(text: "Polylines")],
                         [TGKeyboardButton(text: "Quadratic bezier lines")],
                         [TGKeyboardButton(text: "Surprise me!")]
                        ],
                    oneTimeKeyboard: true
                )
                let params = TGSendMessageParams(
                    chatId: .chat(message.chat.id),
                    messageThreadId: nil, // TODO: ???
                    text: "How would you like your image to be geometrized?",
                    replyToMessageId: message.messageId,
                    replyMarkup: .replyKeyboardMarkup(keyboard)
                )
                try await bot.sendMessage(params: params)
                return .waitShapeType
            },

            .waitShapeType: { update, bot in
                print("waitShapeType")
                guard let message = update.message, let userId = message.from?.id, let text = message.text else { return .waitShapeType }
                let types: Set<ShapeType>
                switch text {
                    case "Rectangles": types = [.rectangle]
                    case "Rotated rectangles": types = [.rotatedRectangle]
                    case "Triangles": types = [.triangle]
                    case "Circles": types = [.circle]
                    case "Ellipses": types = [.ellipse]
                    case "Rotated Ellipses": types = [.rotatedEllipse]
                    case "Lines": types = [.line]
                    case "Polylines": types = [.polyline]
                    case "Quadratic bezier lines": types = [.quadraticBezier]
                    case "Surprise me!": types = Set(ShapeType.allCases)
                    default: return .waitShapeType
                }
                shapeTypes[userId] = types
                let keyboard = TGReplyKeyboardMarkup(
                    keyboard:
                        // Number should divide on 5 without remainder as .waitShapeCount step rely on that
                        [[TGKeyboardButton(text: "50"),
                          TGKeyboardButton(text: "100"),
                          TGKeyboardButton(text: "150")
                         ],
                         [TGKeyboardButton(text: "200"),
                          TGKeyboardButton(text: "250"),
                          TGKeyboardButton(text: "500")
                         ],
                         [TGKeyboardButton(text: "1000"),
                          TGKeyboardButton(text: "5000"),
                          TGKeyboardButton(text: "10000")
                         ]
                        ],
                    oneTimeKeyboard: true
                )
                let params = TGSendMessageParams(
                    chatId: .chat(message.chat.id),
                    messageThreadId: nil, // TODO: ???
                    text: "How many shapes?",
                    replyToMessageId: message.messageId,
                    replyMarkup: .replyKeyboardMarkup(keyboard)
                )
                try await bot.sendMessage(params: params)
                return .waitShapeCount
            },

            .waitShapeCount: { update, bot in
                guard let message = update.message, let userId = message.from?.id, let shapeCount = message.text.flatMap(Int.init), shapeCount > 0 && shapeCount <= 10000 else { return .waitShapeCount }
                shapeCounts[userId] = shapeCount
                guard let imageData = imageDatas[userId], let types = shapeTypes[userId], let shapeCount = shapeCounts[userId]  else {
                    throw "Internal inconsistency"
                }

                let shapesPerIteration: Int
                switch shapeCount {
                case ...100: shapesPerIteration = shapeCount
                case 101...200: shapesPerIteration = shapeCount / 2
                default: shapesPerIteration = shapeCount / 5
                }
                let iterations = shapeCount / shapesPerIteration

                let params = TGSendMessageParams(
                    chatId: .chat(message.chat.id),
                    messageThreadId: nil, // TODO: ???
                    text: "Have started geometrizing with \(shapeCount) \(types.map(\.rawValueCapitalized).joined(separator: "+"))." +
                        (iterations > 1 ?
                             " Will post here \(iterations - 1) intermediary geometrizing results and then final one." :
                            ""
                        ),
                    replyToMessageId: message.messageId
                )
                try await bot.sendMessage(params: params)

                let svgSequence = try await Geometrizer.geometrize(
                    image: imageData.image,
                    maxThumbnailSize: 64,
                    originalPhotoWidth: imageData.originalPhotoWidth,
                    originalPhotoHeight: imageData.originalPhotoHeight,
                    shapeTypes: types,
                    iterations: iterations,
                    shapesPerIteration: shapesPerIteration
                )
                var shapesCounter = shapesPerIteration
                var iteration = 0
                let fileNameNoExt = imageData.fileUrl.lastPathComponent.dropLast(imageData.fileUrl.pathExtension.count + 1)
                for try await result in svgSequence {
                    let filename = "\(fileNameNoExt)-\(shapesCounter)x\(types.map(\.rawValueCapitalized).joined(separator: "+")).svg"
                    let svgData = result.svg.data(using: .utf8)!
                    if let s3Bucket {
                        do {
                            try await uploadToS3(bucket: s3Bucket, fileName: "\(userId)-\(filename)", data: svgData)
                        } catch {
                            print(error)
                        }
                    }

                    let file = TGInputFile(
                        filename: filename,
                        data: svgData,
                        mimeType: "image/svg+xml"
                    )
                    let thumbnail = TGInputFile(
                        filename: filename,
                        data: try result.thumbnail.pngData(),
                        mimeType: "image/x-png"
                    )
                    try await bot.sendDocument(params:
                        TGSendDocumentParams(
                            chatId: .chat(message.chat.id),
                            messageThreadId: nil,  // TODO: ???
                            document: .file(file),
                            thumbnail: .file(thumbnail),
                            caption: iterations > 1 ? "\(iteration + 1)/\(iterations)" : nil,
                            replyToMessageId: imageData.messageId
                        )
                    )
                    shapesCounter += shapesPerIteration
                    iteration += 1
                }
                return .waitImageFromUser
            }

        ]

    private static func messageHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async throws {
        let filters: TGFilter = .all && !.command.names(["/ping", "/help", "/start"])
        let handler = TGMessageHandler(filters: filters) { update, bot in
            // Can react only on messages and thous from users.
            guard let message = update.message, let user = message.from else { return }
            let dialogState = state[user.id, default: .waitImageFromUser]
            guard let action = actions[dialogState] else { throw "No action for state \(dialogState)" }
            state[user.id] = try await action(update, bot)
        }
        await connection.dispatcher.add(handler)
    }

    private static func commandPingHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        let handler = TGCommandHandler(commands: ["/ping"]) { update, bot in
            try await update.message?.reply(text: "pong", bot: bot)
        }
        await connection.dispatcher.add(handler)
    }

    private static func commandHelpHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        let handler = TGCommandHandler(commands: ["/help"]) { update, bot in
            try await update.message?.reply(
                text: """
                    Bot for geometrizing images.
                    /start
                        for starting bot,
                    /ping
                        sends ping message to bot,
                    /help
                        prints this message.
                    """,
                bot: bot
            )
        }
        await connection.dispatcher.add(handler)
    }

    private static func commandStartHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        let handler = TGCommandHandler(commands: ["/start"]) { update, bot in
            guard let message = update.message, let userId = message.from?.id else {
                return
            }
            let params = TGSendMessageParams(
                chatId: .chat(message.chat.id),
                messageThreadId: nil, // TODO: ???
                text: "Try send an image...",
                replyToMessageId: message.messageId
            )
            state[userId] = .waitImageFromUser
            try await connection.bot.sendMessage(params: params)
        }
        await connection.dispatcher.add(handler)
    }

}
