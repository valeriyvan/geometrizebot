import Vapor
import TelegramVaporBot

final class DefaultBotHandlers {

    static func addHandlers(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await messageHandler(app: app, connection: connection)
        await commandPingHandler(app: app, connection: connection)
        await commandHelpHandler(app: app, connection: connection)
        await commandStartHandler(app: app, connection: connection)

    }

    private static func messageHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGMessageHandler(filters: (.all && !.command.names(["/ping", "/help", "/start"])))
        {
            update, bot in
            let chatId = update.message!.chat.id
            //let userId = update.message!.from!.id
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
                for photoSize in photoSizes {
                    let fileId = photoSize.fileId
                    let file = try await connection.bot.getFile(params: TGGetFileParams(fileId: fileId))
                    try await connection.bot.sendPhoto(
                        params: TGSendPhotoParams(
                            chatId: .chat(chatId),
                            photo: .fileId(fileId)
                        )
                    )
                    try await connection.bot.sendMessage(params:
                        TGSendMessageParams(
                            chatId: .chat(chatId),
                            text: """
                            \(file.filePath ?? "no path")
                            id \(file.fileId)
                            size \(file.fileSize.map(String.init) ?? "unknown")
                            """
                        )
                    )
                }
            } else {
                let params = TGSendMessageParams(
                    chatId: .chat(chatId),
                    text: "Bot has got a message but can extract neither text message not document or image."
                )
                try await connection.bot.sendMessage(params: params)
                return
            }
        })
    }

    private static func commandPingHandler(app: Vapor.Application, connection: TGConnectionPrtcl) async {
        await connection.dispatcher.add(TGCommandHandler(commands: ["/ping"]) { update, bot in
            try await update.message?.reply(text: "pong", bot: bot)
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
