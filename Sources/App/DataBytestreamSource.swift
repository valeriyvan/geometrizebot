import Foundation
import JPEG

internal struct DataBytestreamSource: _JPEGBytestreamSource {
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
