import Foundation
import Geometrize
import JPEG

enum Geometrizer {

    // Returns SVGAsyncSequence which produces intermediate geometrizing results
    // which are SVG strings + thumbnails. The last sequence element is final result.
    static func geometrize(
        image: Image,
        maxThumbnailSize: Int,
        originalPhotoWidth: Int, originalPhotoHeight: Int,
        shapeTypes: Set<ShapeType>,
        iterations: Int, shapesPerIteration: Int
    ) async throws -> SVGAsyncSequence {
        SVGAsyncSequence(
            image: image,
            maxThumbnailSize: maxThumbnailSize,
            originalPhotoWidth: originalPhotoWidth,
            originalPhotoHeight: originalPhotoHeight,
            shapeTypes: shapeTypes,
            iterations: iterations, shapesPerIteration: shapesPerIteration
        )
    }

}

struct SVGIterator: AsyncIteratorProtocol {
    private let thumbnailDownsizeFactor: Int
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
        maxThumbnailSize: Int,
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
            (rgb, width, height) = try! JPEG.rgba(fromJPEGData: data)
        case .png(let data):
            print("Encounter PNG. This will crash!!!")
            (rgb, width, height) = try! JPEG.rgba(fromJPEGData: data)
        }
        thumbnailDownsizeFactor = max(width, height) / maxThumbnailSize
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

    mutating func next() async throws -> GeometrizingResult? {
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
        return GeometrizingResult(svg: svg, thumbnail: runner.currentBitmap)
    }

}

struct GeometrizingResult {
    let svg: String
    let thumbnail: Bitmap
}

struct SVGAsyncSequence: AsyncSequence {
    typealias Element = GeometrizingResult

    let image: Image
    let maxThumbnailSize: Int
    let originalPhotoWidth: Int
    let originalPhotoHeight: Int
    let shapeTypes: Set<ShapeType>
    let iterations: Int
    let shapesPerIteration: Int

    func makeAsyncIterator() -> SVGIterator {
        SVGIterator(
            image: image,
            maxThumbnailSize: maxThumbnailSize,
            originalPhotoWidth: originalPhotoWidth,
            originalPhotoHeight: originalPhotoHeight,
            shapeTypes: shapeTypes,
            iterations: iterations,
            shapesPerIteration: shapesPerIteration
        )
    }
}
