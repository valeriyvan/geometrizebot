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
            let userId = update.message!.from!.id
            if let text = update.message?.text {
                let params = TGSendMessageParams(
                    chatId: .chat(chatId),
                    text: "Reply to \"\(text)\""
                )
                try await connection.bot.sendMessage(params: params)
            } else if let document = update.message?.document {
                let fileId = document.fileId
                try await connection.bot.getFile(params: TGGetFileParams(fileId: fileId))
                let params = TGSendMessageParams(
                    chatId: .chat(chatId),
                    text: fileId
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
                let geometrizer = Geometrizer()
                let svg = try await geometrizer.geometrize(image: image, originalPhotoWidth: originalPhotoWidth, originalPhotoHeight: originalPhotoHeight, shapeTypes: [.rotatedEllipse], shapeCount: 250)
                // This works but attachment doesn't look nice on side of telegram app
                try await connection.bot.sendDocument(params:
                    TGSendDocumentParams(
                        chatId: .chat(chatId),
                        document: .file(TGInputFile(filename: "\(fileNameNoExt)-250xRotatedElipses.svg", data: svg.data(using: .utf8)!, mimeType: "image/svg+xml"))
                    )
                )
            } else {
                let params = TGSendMessageParams(
                    chatId: .chat(chatId),
                    text: "Bot has got a message but can extract neither text message not document or image."
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
            let params = TGSendMessageParams(
                chatId: .chat(chatId),
                text: "Try send an image..."
            )
            try await connection.bot.sendMessage(params: params)
        })
    }

}
