import Vapor
import Geometrize
import Leaf

func routes(_ app: Application) throws {
    app.get { req in
        req.leaf.render("index")
    }

    app.post("upload") { req async throws -> View in
        struct Input: Content {
            var shape: String
            var file: File
        }
        let input: Input = try req.content.decode(Input.self)

        let selectedShapeName = input.shape
        let allShapeTypeStrings = allShapeTypes.map { String("\(type(of: $0))".dropLast(5)) } // /* drop .Type */
        let selectedShapeIndex = allShapeTypeStrings.firstIndex(of: selectedShapeName)
        let selectedShape = selectedShapeIndex.flatMap({ allShapeTypes[$0] }) ?? RotatedEllipse.self

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
            maxThumbnailSize: 64,
            originalPhotoWidth: 500,
            originalPhotoHeight: 500,
            shapeTypes: [selectedShape],
            strokeWidth: 1,
            iterations: 1,
            shapesPerIteration: 200
        )
        var shapesCounter = 200 // shapesPerIteration
        var iteration = 0
        let fileNameNoExt = URL(fileURLWithPath: input.file.filename).lastPathComponent.dropLast(URL(fileURLWithPath: input.file.filename).pathExtension.count + 1)

        let results = try await svgSequence.reduce(into: [GeometrizingResult]()) { $0.append($1) }
        let svgLines = results.last!.svg.components(separatedBy: .newlines)
        let svg = svgLines.dropFirst(2).joined(separator: "\n")
        return try await req.view.render(
           "result",
           [
                "fileUrl": "fileName.svg",
                "svg": svg,
                "isImage": "true"
            ]
        )
    }

}
