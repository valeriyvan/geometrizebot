import Foundation
import PNG
import struct Geometrize.Bitmap

extension PNG {

    static func rgba(fromPNGData data: Foundation.Data) throws -> ([UInt8], width: Int, height: Int) {
        var bytestreamSource = DataBytestreamSource(data: data)
        guard let image: PNG.Data.Rectangular = try .decompress(stream: &bytestreamSource) else {
            throw "Cannot decompress PNG data"
        }
        let rgb: [PNG.RGBA<UInt8>] = image.unpack(as: PNG.RGBA<UInt8>.self)
        let (width, height) = image.size
        let data: [UInt8] = rgb.flatMap({ [$0.r, $0.g, $0.b, $0.a] })
        return (data, width, height)
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
