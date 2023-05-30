import Foundation

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
}
