import Vapor
import Geometrize
import Leaf

var cache: [String: (date: Date, iterator: SVGAsyncIterator)] = [:]

var iterators: [UUID: (date: Date, iterator: SVGAsyncIterator)] = [:]

func routes(_ app: Application) throws {
    let updateMarker = "<!-- insert here next shapes -->\n"

    app.get { req in
        cleanup()
        return req.leaf.render("index")
    }

    app.post("geometrize", "start", ":id", ":steps") { req async throws in
        cleanup()

        guard let id: String = req.parameters.get("id"),
              let steps: Int = req.parameters.get("steps").flatMap(Int.init) else {
            throw "Inconsistent request"
        }

        struct Input: Content {
            var shape: String // TODO: shapes
            var count: String
            var file: File
        }
        let input: Input = try req.content.decode(Input.self)

        let selectedShape = shapeType(from: input.shape.replacingOccurrences(of: " ", with: "")) ?? RotatedEllipse.self

        let shapeCount = Int(input.count)
        guard let shapeCount else {
            throw "Invalid shape count \(input.count)"
        }

        guard let data = input.file.data.getData(at: 0, length: input.file.data.writerIndex) else {
            throw "Cannot process file \(input.file.filename)"
        }
        let bitmap: Bitmap
        switch URL(fileURLWithPath: input.file.filename).pathExtension.lowercased() {
        case "jpg", "jpeg":
            bitmap = try Bitmap(jpeg: data)
        case "png":
            bitmap = try Bitmap(png: data)
        default:
            throw "Cannot process file \(input.file.filename)"
        }

        let svgSequence: SVGAsyncSequence = try await SVGAsyncGeometrizer.geometrize(
            bitmap: bitmap,
            shapeTypes: [selectedShape],
            strokeWidth: 1,
            iterations: steps,
            shapesPerIteration: shapeCount / steps, 
            iterationOptions: .completeSVGEachIteration
        )
        var asyncIterator = svgSequence.makeAsyncIterator()
        cache[id] = (date: Date(), iterator: asyncIterator)
        guard let result = try await asyncIterator.next() else {
            throw "No next element"
        }
        let svgLines = result.svg.components(separatedBy: .newlines)
        let svg = svgLines.dropFirst(2).joined(separator: "\n")
        return svg
    }

    app.get("geometrize", "continue", ":id") { req async throws in
        cleanup()

        guard let id: String = req.parameters.get("id") else {
            throw "Inconsistent request"
        }
        guard var asyncIterator = cache[id]?.iterator else {
            throw "Internal inconsistency"
        }
        guard let result = try await asyncIterator.next() else {
            throw "No next element"
        }
        cache[id] = (date: Date(), iterator: asyncIterator)
        let svgLines = result.svg.components(separatedBy: .newlines)
        let svg = svgLines.dropFirst(2).joined(separator: "\n")
        return svg
    }

    app.post("geometrize", "ws") { req async throws in
        cleanup()

        struct Input: Content {
            var shape: String // TODO: shapes
            var count: String
            var file: File
        }
        let input: Input = try req.content.decode(Input.self)

        let selectedShape = shapeType(from: input.shape.replacingOccurrences(of: " ", with: "")) ?? RotatedEllipse.self

        let shapeCount = Int(input.count)
        guard let shapeCount else {
            throw "Invalid shape count \(input.count)"
        }

        guard let data = input.file.data.getData(at: 0, length: input.file.data.writerIndex) else {
            throw "Cannot process file \(input.file.filename)"
        }
        let bitmap: Bitmap
        switch URL(fileURLWithPath: input.file.filename).pathExtension.lowercased() {
        case "jpg", "jpeg":
            bitmap = try Bitmap(jpeg: data)
        case "png":
            bitmap = try Bitmap(png: data)
        default:
            throw "Cannot process file \(input.file.filename)"
        }

        let svgSequence: SVGAsyncSequence = try await SVGAsyncGeometrizer.geometrize(
            bitmap: bitmap,
            shapeTypes: [selectedShape],
            strokeWidth: 1,
            iterations: shapeCount,
            shapesPerIteration: 1,
            iterationOptions: .completeSVGFirstIterationThenDeltas(updateMarker: updateMarker)
        )
        let asyncIterator = svgSequence.makeAsyncIterator()
        let uuid = UUID()
        iterators[uuid] = (date: Date(), iterator: asyncIterator)
        return uuid.uuidString
    }

    app.webSocket(":uuid") { req, ws async in // throws ???
        cleanup()

        guard let uuidString = req.parameters.get("uuid"),
            let uuid = UUID(uuidString: uuidString),
            var (_, iterator) = iterators[uuid]
        else {
            try? await ws.close(code: .unacceptableData)
            return
        }
        var firstSVG: String? = nil
        var svgAdOns: String = ""
        // for try await result in svgSequence { TODO: do this!
        while let result = try? await iterator.next() {
            if let firstSVG {
                svgAdOns += result.svg
                let fullSVG = firstSVG.replacingOccurrences(of: updateMarker, with: svgAdOns)
                try? await ws.send(fullSVG)
            } else {
                let svgLines = result.svg.components(separatedBy: .newlines)
                let firstSVG_ = svgLines.dropFirst(2).joined(separator: "\n")
                try? await ws.send(firstSVG_)
                firstSVG = firstSVG_
            }
        }
        try? await ws.close()
    }
}

private func cleanup() {
    let cleanupInterval: TimeInterval = 60.0 * 60.0
    let now = Date()
    cache = cache.filter { now.timeIntervalSince($0.value.date) < cleanupInterval }
    iterators = iterators.filter { now.timeIntervalSince($0.value.date) < cleanupInterval }
}

// TODO: remove on next swift-geometrize update
func shapeType(from string: String) -> Shape.Type? {
    allShapeTypes
        .map { String("\(type(of: $0))".dropLast(5) /* drop .Type */) }
        .firstIndex(of: string)
        .flatMap { allShapeTypes[$0] }
}
