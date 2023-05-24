import Foundation
import JPEG

func rgbOfJpeg(data: Data) async throws -> ([UInt8], width: Int, height: Int) {
    var bytestreamSource = DataBytestreamSource(data: data)
    guard let image: JPEG.Data.Rectangular<JPEG.Common> = try .decompress(stream: &bytestreamSource) else {
        throw "Cannot decompress JPEG data"
    }
    let rgb: [JPEG.RGB] = image.unpack(as: JPEG.RGB.self)
    let (width, height) = image.size
    let data: [UInt8] = rgb.flatMap({ [$0.r, $0.g, $0.b, 255] })
    return (data, width, height)
}
