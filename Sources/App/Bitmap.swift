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

    // Transposes Bitmap
    mutating func transpose() {
        self = Bitmap(width: height, height: width) {
            self[$1, $0]
        }
    }

    mutating func swap(x1: Int, y1: Int, x2: Int, y2: Int) {
        let copy = self[x1, y1]
        self[x1, y1] = self[x2, y2]
        self[x2, y2] = copy
    }

    // Reflects Bitmap vertically
    mutating func reflectVertically() {
        for x in 0 ..< width / 2 {
            for y in 0 ..< height {
                swap(x1: x, y1: y, x2: width - x - 1, y2: y)
            }
        }
    }

    // Reflects Bitmap horizontally
    mutating func reflectHorizontally() {
        for x in 0 ..< width {
            for y in 0 ..< height / 2 {
                swap(x1: x, y1: y, x2: x, y2: height - y - 1)
            }
        }
    }


}

private struct DestinationStream: PNG.Bytestream.Destination {

    private(set) var data: [UInt8] = []

    mutating func write(_ buffer: [UInt8]) -> Void? {
        data.append(contentsOf: buffer)
    }

}
