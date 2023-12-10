import Foundation
import JPEG
import struct Geometrize.Bitmap

extension Bitmap {
    init(jpeg data: Data) throws {
        var bytestreamSource = DataBytestreamSource(data: data)
        guard let image: JPEG.Data.Rectangular<JPEG.Common> = try .decompress(stream: &bytestreamSource) else {
            throw "Cannot decompress JPEG data"
        }
        let rgb: [JPEG.RGB] = image.unpack(as: JPEG.RGB.self)
        let (width, height) = image.size
        let rgba: [UInt8] = rgb.flatMap({ [$0.r, $0.g, $0.b, 255] })
        var bitmap = Bitmap(width: width, height: height, data: rgba)
        for m in image.metadata {
            switch m {
            case .exif(let exif):
                if let orientationTag = exif[tag: 0x112] {
                    let orientation = orientationTag.box.endianness == .littleEndian ? orientationTag.box.contents.0 : orientationTag.box.contents.1
                    switch orientation {
                        // https://home.jeita.or.jp/tsc/std-pdf/CP3451C.pdf, page 30
                    case 1: // 1 The Oth row is at the visual top of the image, and the 0th column is the visual left-hand side.
                        // normal orientation
                        ()
                    case 2: // 2 The Oth row is at the visual top of the image, and the Oth column is the visual right-hand side.
                        bitmap.reflectVertically()
                    case 3: // 3 The Oth row is at the visual bottom of the image, and the Oth column is the visual right-hand side.
                        bitmap.reflectHorizontally()
                    case 4: // 4 The Oth row is at the visual bottom of the image, and the 0th column is the visual left-hand side.
                        bitmap.reflectHorizontally()
                        bitmap.reflectVertically()
                    case 5: // 5 The Oth row is the visual left-hand side of the image, and the 0th column is the visual top.
                        bitmap.transpose()
                        bitmap.transpose()
                        bitmap.transpose()
                        bitmap.reflectVertically()
                        bitmap.reflectHorizontally()
                    case 6: // 6 The Oth row is the visual right-hand side of the image, and the 0th column is the visual top.
                        bitmap.transpose()
                        bitmap.reflectVertically()
                    case 7: // 7 The Oth row is the visual right-hand side of the image, and the 0th column is the visual bottom.
                        bitmap.transpose()
                        bitmap.reflectVertically()
                    case 8: // 8 The Oth row is the visual left-hand side of the image, and the 0th column is the visual bottom.
                        bitmap.transpose()
                    default:
                        ()
                    }
                }
            default:
                ()
            }
        }
        self = bitmap
    }
}

private struct DataBytestreamSource: _JPEGBytestreamSource {
    init(data: Data) {
        self.data = data
        offset = 0
    }

    let data: Data

    private var offset: Int

    mutating func read(count: Int) -> [UInt8]? {
        defer { offset += count }
        return Array(data[offset ..< offset + count])
    }
}
