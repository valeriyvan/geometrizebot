import Foundation
import JPEG
import PNG

enum Image {
    case jpeg(Data)
    case png(Data)

    var data: Data {
        switch self {
        case .jpeg(let data): return data
        case .png(let data): return data
        }
    }

    var mimeType: String {
        switch self {
        case .jpeg: return "image/jpeg"
        case .png: return "image/x-png"
        }
    }

    func rgba() throws -> ([UInt8], width: Int, height: Int) {
        switch self {
        case .jpeg(let data):
            return try JPEG.rgba(fromJPEGData: data)
        case .png(let data):
            return try PNG.rgba(fromPNGData: data)
        }

    }
}
