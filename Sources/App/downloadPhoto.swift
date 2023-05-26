import Foundation
import TelegramVaporBot
#if canImport(FoundationNetworking)
    import FoundationNetworking // URLSession on Linux
#endif

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

    // simple `try await URLSession.shared.data(from: url)` is impossible
    // because `data` property is unavailable on Linux
    let data: Data? = await withCheckedContinuation { continuation in
        URLSession.shared.dataTask(with: url) { data, _, _ in
            continuation.resume(returning: data)
        }.resume()
    }

    guard let data else {
        throw "Error downloading file \(filePath)"
    }

    print("Downloaded photo \(filePath) width \(photoSize.width), height \(photoSize.height)")

    return (data, filePath)
}
