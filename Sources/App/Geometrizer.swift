import Foundation
import Geometrize
import JPEG

enum Geometrizer {

    // Returns SVGAsyncSequence which produces intermediate geometrizing results
    // which are SVG strings. The last sequence element is final geometrizing result.
    static func geometrize(
        image: Image,
        originalPhotoWidth: Int, originalPhotoHeight: Int,
        shapeTypes: Set<ShapeType>,
        iterations: Int, shapesPerIteration: Int
    ) async throws -> SVGAsyncSequence {
        SVGAsyncSequence(
            image: image,
            originalPhotoWidth: originalPhotoWidth,
            originalPhotoHeight: originalPhotoHeight,
            shapeTypes: shapeTypes,
            iterations: iterations, shapesPerIteration: shapesPerIteration
        )
    }

}

struct SVGIterator: AsyncIteratorProtocol {
    private let originalPhotoWidth: Int
    private let originalPhotoHeight: Int
    private let shapeTypes: Set<ShapeType>
    private let iterations: Int
    private let shapesPerIteration: Int

    private let rgb: [UInt8]
    private let width, height: Int

    private var iterationCounter: Int

    private var shapeData: [ShapeResult]

    private let runnerOptions: ImageRunnerOptions
    private var runner: ImageRunner

    // Counts attempts to add shapes. Not all attempts to add shape result in adding a shape.
    private var stepCounter: Int

    let targetBitmap: Bitmap
    init(
        image: Image,
        originalPhotoWidth: Int,
        originalPhotoHeight: Int,
        shapeTypes: Set<ShapeType>,
        iterations: Int,
        shapesPerIteration: Int
    ) {
        self.originalPhotoWidth = originalPhotoWidth
        self.originalPhotoHeight = originalPhotoHeight
        self.shapeTypes = shapeTypes
        self.iterations = iterations
        self.shapesPerIteration = shapesPerIteration
        // TODO: fix this!
        switch image {
        case .jpeg(let data):
            (rgb, width, height) = try! rgbOfJpeg(data: data)
        case .png(let data):
            print("Encounter PNG. This will crash!!!")
            (rgb, width, height) = try! rgbOfJpeg(data: data)
        }

        targetBitmap = Bitmap(width: width, height: height, data: rgb)

        iterationCounter = 0

        stepCounter = 0

        runnerOptions = ImageRunnerOptions(
            shapeTypes: shapeTypes,
            alpha: 128,
            shapeCount: 500,
            maxShapeMutations: 100,
            seed: 9001,
            maxThreads: 1,
            shapeBounds: ImageRunnerShapeBoundsOptions(
                enabled: false,
                xMinPercent: 0, yMinPercent: 0, xMaxPercent: 100, yMaxPercent: 100
            )
        )

        runner = ImageRunner(targetBitmap: targetBitmap)

        shapeData = []

        // Hack to add a single background rectangle as the initial shape
        shapeData.append(
            ShapeResult(
                score: 0,
                color: targetBitmap.averageColor(),
                shape: Rectangle(canvasWidth: targetBitmap.width, height: targetBitmap.height)
            )
        )
    }

    mutating func next() async throws -> String? {
        guard iterationCounter < iterations else { return nil }
        var stepShapeData: [ShapeResult] = []
        while stepShapeData.count < shapesPerIteration {
            print("Step \(stepCounter)", terminator: "")
            let shapes = runner.step(options: runnerOptions, shapeCreator: nil, energyFunction: defaultEnergyFunction, addShapePrecondition: defaultAddShapePrecondition)
            if shapes.isEmpty {
                print(", no shapes added.", terminator: "")
            } else {
                print(", \(shapes.map(\.shape).map(\.description).joined(separator: ", ")) added.", terminator: "")
            }
            print(" Total count of shapes \(shapeData.count + stepShapeData.count).")
            stepShapeData.append(contentsOf: shapes)
            stepCounter += 1
        }

        shapeData.append(contentsOf: stepShapeData)
        iterationCounter += 1

        var svg = SVGExporter().export(data: shapeData, width: width, height: height)

        // Fix SVG to keep original image size
        let range = svg.range(of: "width=")!.lowerBound ..< svg.range(of: "viewBox=")!.lowerBound
        svg.replaceSubrange(range.relative(to: svg), with: " width=\"\(originalPhotoWidth)\" height=\"\(originalPhotoHeight)\" ")

        print("Iteration \(iterationCounter), shapes in iteration \(stepShapeData.count), total shapes \(shapeData.count)")
        return svg
    }

}

struct SVGAsyncSequence: AsyncSequence {
    typealias Element = String

    let image: Image
    let originalPhotoWidth: Int
    let originalPhotoHeight: Int
    let shapeTypes: Set<ShapeType>
    let iterations: Int
    let shapesPerIteration: Int

    func makeAsyncIterator() -> SVGIterator {
        SVGIterator(
            image: image,
            originalPhotoWidth: originalPhotoWidth,
            originalPhotoHeight: originalPhotoHeight,
            shapeTypes: shapeTypes,
            iterations: iterations,
            shapesPerIteration: shapesPerIteration
        )
    }
}

private extension Rectangle {

    // Rectangle taking whole size of canvas
    convenience init(canvasWidth width: Int, height: Int) {
        self.init(
            canvasBoundsProvider: { Bounds(xMin: 0, xMax: width, yMin: 0, yMax: height) },
            x1: 0.0, y1: 0.0, x2: Double(width), y2: Double(height)
        )
    }

}

private func rgbOfJpeg(data: Data) throws -> ([UInt8], width: Int, height: Int) {
    var bytestreamSource = DataBytestreamSource(data: data)
    guard let image: JPEG.Data.Rectangular<JPEG.Common> = try .decompress(stream: &bytestreamSource) else {
        throw "Cannot decompress JPEG data"
    }
    let rgb: [JPEG.RGB] = image.unpack(as: JPEG.RGB.self)
    let (width, height) = image.size
    let data: [UInt8] = rgb.flatMap({ [$0.r, $0.g, $0.b, 255] })
    return (data, width, height)
}
