import Vapor
import TelegramVaporBot
import Geometrize
import JPEG

final class DefaultBotHandlers {

    static func addHandlers(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await messageHandler(app: app, connection: connection)
        await commandPingHandler(app: app, connection: connection)
        await commandHelpHandler(app: app, connection: connection)
        await commandStartHandler(app: app, connection: connection)
        await commandParametersHandler(app: app, connection: connection)
    }

    private static func messageHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
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
                let fileName = URL(fileURLWithPath: filePath).lastPathComponent
                if let s3Bucket {
                    do {
                        try await uploadToS3(bucket: s3Bucket, fileName: "\(userId)-\(fileName)", data: photoData)
                    } catch {
                        print(error)
                    }
                }

                switch URL(fileURLWithPath: filePath).pathExtension.lowercased() {
                case "jpg", "jpeg":
                    let (rgb, width, height) = try await rgbOfJpeg(data: photoData)
                    var svg = await geometrizeToSvg(rgb: rgb, width: width, height: height, shapeTypes: [.rotatedEllipse], shapeCount: 250)
                    let (originalPhotoWidth, originalPhotoHeight) = photoSizes.map { ($0.width, $0.height) }.max { $0.0 < $1.0 }!
                    // Fix SVG to keep original image size
                    let range = svg.range(of: "width=")!.lowerBound ..< svg.range(of: "viewBox=")!.lowerBound
                    //print(svg[range])
                    svg.replaceSubrange(range.relative(to: svg), with: " width=\"\(originalPhotoWidth)\" height=\"\(originalPhotoHeight)\" ")
                    // This works but attachment doesn't look nice on side of telegram app
                    try await connection.bot.sendDocument(params:
                        TGSendDocumentParams(
                            chatId: .chat(chatId),
                            document: .file(TGInputFile(filename: "\(fileName)-250xRotatedElipses.svg", data: svg.data(using: .utf8)!, mimeType: "image/svg+xml"))
                        )
                    )
                case "png":
                    print("Processing PNG is not implemented")
                default:
                    print("Cannot process file \(filePath)")
                }
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
