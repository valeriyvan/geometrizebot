import Foundation
import TelegramVaporBot

extension String: Error {}

internal func downloadPhoto(bot: TGBot, tgToken: String, photoSizes: [TGPhotoSize], maxHeightAndWidth: Int) async throws -> (Data, String) {
    guard !photoSizes.isEmpty else { throw "Empty sizes" }
    print("\(photoSizes.count) photo sizes are available")
    let maxPhotoSize = photoSizes.max { $0.width < $1.width }!
    print("Max available photo size width \(maxPhotoSize.width), height \(maxPhotoSize.height)")
    let index = photoSizes
        .map { max($0.width, $0.height) }
        .sorted()
        .lastIndex { $0 <= maxHeightAndWidth }
        ?? 0 // choose the first element if there's no proper size
    print("#function index \(index)")
    let photoSize = photoSizes[index]
    print("Going to download photo width \(photoSize.width), height \(photoSize.height)")
    let fileId = photoSize.fileId
    let file = try await bot.getFile(params: TGGetFileParams(fileId: fileId))
    guard let filePath = file.filePath else {
        throw "TGPhotoSize doesn't have filePath needed to download file"
    }
    let urlString = "https://api.telegram.org/file/bot\(tgToken)/\(filePath)"
    guard let url = URL(string: urlString) else {
        throw "Cannot build url from \"\("https://api.telegram.org/file/bot\(tgToken)/\(filePath)\"")"
    }
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw "Error downloading file"
    }
    return (data, filePath)
}
