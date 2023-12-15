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
        let exifOrientation = Bitmap.ExifOrientation(rawValue: image.exifOrientation()) ?? .up
        bitmap.rotateToUpOrientation(accordingTo: exifOrientation)
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

extension JPEG.Data.Rectangular<JPEG.Common> {

    func exifOrientation() -> Int {
        for m in metadata {
            switch m {
            case .exif(let exif):
                if let orientationTag = exif[tag: 0x112] {
                    let orientation = orientationTag.box.endianness == .littleEndian ? orientationTag.box.contents.0 : orientationTag.box.contents.1
                    return Int(orientation)
                }
            default:
                ()
            }
        }
        return 1
    }

}
