import Foundation
import PNG
import struct Geometrize.Bitmap

// TODO: avoid code duplication of this file with swift-geometrize package.

extension Bitmap {

    func pngData() throws -> Data {
        let rgba: [PNG.RGBA<UInt8>] = backing.chunks(ofCount: 4).map {
            PNG.RGBA(
                $0[$0.startIndex + 0],
                $0[$0.startIndex + 1],
                $0[$0.startIndex + 2],
                $0[$0.startIndex + 3]
            )
        }
        let image: PNG.Data.Rectangular = PNG.Data.Rectangular(packing: rgba, size: (x: width, y: height), layout: PNG.Layout(format: .rgba8(palette: [], fill: nil)))
        var destinationStream = DestinationStream()
        try image.compress(stream: &destinationStream)
        return Data(destinationStream.data)
    }

}

private struct DestinationStream: PNG.Bytestream.Destination {

    private(set) var data: [UInt8] = []

    mutating func write(_ buffer: [UInt8]) -> Void? {
        data.append(contentsOf: buffer)
    }

}
