import Vapor
import Geometrize
import Leaf

func routes(_ app: Application) throws {
    app.get { req in
        req.leaf.render("index")
    }

    app.post("ajax") { req async throws in
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

        let svgSequence = try await Geometrizer.geometrize(
            image: image,
            shapeTypes: [selectedShape],
            strokeWidth: 1,
            iterations: 1,
            shapesPerIteration: shapeCount
        )
        let fileNameNoExt = URL(fileURLWithPath: input.file.filename).lastPathComponent.dropLast(URL(fileURLWithPath: input.file.filename).pathExtension.count + 1)

        let results = try await svgSequence.reduce(into: [GeometrizingResult]()) { $0.append($1) }
        let svgLines = results.last!.svg.components(separatedBy: .newlines)
        let svg = svgLines.dropFirst(2).joined(separator: "\n")
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
