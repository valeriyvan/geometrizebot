import Foundation
import PNG
import struct Geometrize.Bitmap

extension Bitmap {
    init(png data: Data) throws {
        var bytestreamSource = DataBytestreamSource(data: data)
        guard let image: PNG.Data.Rectangular = try .decompress(stream: &bytestreamSource) else {
            throw "Cannot decompress PNG data"
        }
        let rgb: [PNG.RGBA<UInt8>] = image.unpack(as: PNG.RGBA<UInt8>.self)
        let (width, height) = image.size
        let rgba: [UInt8] = rgb.flatMap({ [$0.r, $0.g, $0.b, $0.a] })
        let bitmap = Bitmap(width: width, height: height, data: rgba)
        self = bitmap
    }
}

private struct DataBytestreamSource: _PNGBytestreamSource {
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
