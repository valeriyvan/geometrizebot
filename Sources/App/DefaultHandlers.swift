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
        await commandParametersHandler(app: app, connection: connection)
    }

    private static func messageHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async throws {
        print(#function)
        await connection.dispatcher.add(TGMessageHandler(filters: (.all && !.command.names(["/ping", "/help", "/start"])))
        {
            update, bot in
            let chatId = update.message!.chat.id
            let messageId = update.message!.messageId
            let userId = update.message!.from!.id
            if let text = update.message?.text {
                let params = TGSendMessageParams(
                    chatId: .chat(chatId),
                    messageThreadId: nil, // ???
                    text: "Reply to \"\(text)\"",
                    replyToMessageId: messageId
                )
                try await connection.bot.sendMessage(params: params)
            } else if let document = update.message?.document {
                let fileId = document.fileId
                try await connection.bot.getFile(params: TGGetFileParams(fileId: fileId))
                let params = TGSendMessageParams(
                    chatId: .chat(chatId),
                    messageThreadId: nil, // TODO: ???
                    text: fileId,
                    replyToMessageId: messageId
                )
                try await connection.bot.sendMessage(params: params)
            } else if let photoSizes = update.message?.photo {
                let (photoData, filePath) = try await downloadPhoto(bot: connection.bot, tgToken: tgToken, photoSizes: photoSizes, maxHeightAndWidth: 512)
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
                let iterations = 5
                let shapesPerIteration = 50
                let svgSequence = try await Geometrizer.geometrize(image: image, originalPhotoWidth: originalPhotoWidth, originalPhotoHeight: originalPhotoHeight, shapeTypes: [.rotatedEllipse], iterations: iterations, shapesPerIteration: shapesPerIteration)
                var shapesCounter = 50
                var iteration = 0
                var msg = "Have started geometrizing image \(fileNameWithExt)."
                if iterations > 1 {
                    msg += " Will post here \(iterations - 1) intermediary geometrizing results and then final."
                }
                let params = TGSendMessageParams(
                    chatId: .chat(chatId),
                    messageThreadId: nil, // TODO: ???
                    text: msg,
                    replyToMessageId: messageId
                )
                try await connection.bot.sendMessage(params: params)
                for try await svg in svgSequence {
                    // This works but attachment doesn't look nice on side of telegram app
                    if iterations > 1 {
                        let params1 = TGSendMessageParams(
                            chatId: .chat(chatId),
                            messageThreadId: nil, // TODO: ???
                            text: "It's \(iteration + 1)/\(iterations) intermediate result of geometrizing image \(fileNameWithExt).",
                            replyToMessageId: messageId
                        )
                        try await connection.bot.sendMessage(params: params1)
                    }
                    let filename = "\(fileNameNoExt)-\(shapesCounter)xRotatedElipses.svg"
                    let file = TGInputFile(
                        filename: filename,
                        data: svg.data(using: .utf8)!,
                        mimeType: "image/svg+xml"
                    )
                    // TODO: make preview of SVG
                    //let thumbnail = TGInputFile(
                    //    filename: filename,
                    //    data: image.data,
                    //    mimeType: image.mimeType
                    //)
                    try await connection.bot.sendDocument(params:
                        TGSendDocumentParams(
                            chatId: .chat(chatId),
                            messageThreadId: nil,  // TODO: ???
                            document: .file(file),
                            thumbnail: nil,        // TODO: make preview of SVG
                            replyToMessageId: messageId
                        )
                    )
                    shapesCounter += shapesPerIteration
                    iteration += 1
                }
            } else {
                let params = TGSendMessageParams(
                    chatId: .chat(chatId),
                    messageThreadId: nil, // TODO: ???
                    text: "Bot has got a message but can extract neither text message not document or image.",
                    replyToMessageId: messageId
                )
                try await connection.bot.sendMessage(params: params)
            }
        })
    }

    private static func commandPingHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/ping"]) { update, bot in
            try await update.message?.reply(text: "pong", bot: bot)
        })
    }

    private static func commandParametersHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/parameters"]) { update, bot in
            try await update.message?.reply(text: "Coming soon...", bot: bot)
        })
    }

    private static func commandHelpHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/help"]) { update, bot in
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
        })
    }

    private static func commandStartHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/start"]) { update, bot in
            let chatId = update.message!.chat.id
            let messageId = update.message!.messageId
            let params = TGSendMessageParams(
                chatId: .chat(chatId),
                messageThreadId: nil, // TODO: ???
                text: "Try send an image...",
                replyToMessageId: messageId
            )
            try await connection.bot.sendMessage(params: params)
        })
    }

}
