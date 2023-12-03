import Vapor
import Geometrize
import Leaf

var cache: [String: SVGIterator] = [:]

func routes(_ app: Application) throws {
    app.get { req in
        req.leaf.render("index")
    }

    app.post("geometrize", "start", ":id", ":steps") { req async throws in
        guard let id: String = req.parameters.get("id"),
              let steps: Int = req.parameters.get("steps").flatMap(Int.init) else {
            throw "Inconsistent request"
        }

        struct Input: Content {
            var shape: String
            var count: String
            var file: File
        }
        let input: Input = try req.content.decode(Input.self)

        let selectedShape = shapeType(from: input.shape.replacingOccurrences(of: " ", with: "")) ?? RotatedEllipse.self

        let shapeCount = Int(input.count)
        guard let shapeCount else {
            throw "Invalid shape count \(input.count)"
        }

        let path = app.directory.publicDirectory + input.file.filename

        let image: Image
        switch URL(fileURLWithPath: input.file.filename).pathExtension.lowercased() {
        case "jpg", "jpeg":
            image = .jpeg(input.file.data.getData(at: 0, length: input.file.data.writerIndex) ?? Data())
        case "png":
            image = .png(input.file.data.getData(at: 0, length: input.file.data.writerIndex) ?? Data())
        default:
            throw "Cannot process file \(input.file.filename)"
        }

        let svgSequence: SVGAsyncSequence = try await Geometrizer.geometrize(
            image: image,
            shapeTypes: [selectedShape],
            strokeWidth: 1,
            iterations: steps,
            shapesPerIteration: shapeCount / steps
        )
        var asyncIterator = svgSequence.makeAsyncIterator()
        cache[id] = asyncIterator
        guard let result = try await asyncIterator.next() else {
            throw "No next element"
        }
        let svgLines = result.svg.components(separatedBy: .newlines)
        let svg = svgLines.dropFirst(2).joined(separator: "\n")
        return svg
    }

    app.get("geometrize", "continue", ":id") { req async throws in
        guard let id: String = req.parameters.get("id") else {
            throw "Inconsistent request"
        }
        guard var asyncIterator = cache[id] else {
            throw "Internal inconsistency"
        }
        guard let result = try await asyncIterator.next() else {
            throw "No next element"
        }
        cache[id] = asyncIterator
        let svgLines = result.svg.components(separatedBy: .newlines)
        let svg = svgLines.dropFirst(2).joined(separator: "\n")
        //print(svg)
        return svg
    }
}

// TODO: remove on next swift-geometrize update
func shapeType(from string: String) -> Shape.Type? {
    allShapeTypes
        .map { String("\(type(of: $0))".dropLast(5) /* drop .Type */) }
        .firstIndex(of: string)
        .flatMap { allShapeTypes[$0] }
}
