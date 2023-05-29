import Foundation
import Geometrize
import JPEG

struct Geometrizer {

    func geometrize(image: Image, originalPhotoWidth: Int, originalPhotoHeight: Int, shapeTypes: Set<ShapeType>, shapeCount: Int) async throws -> String {
        let rgb: [UInt8]
        let width, height: Int
        switch image {
        case .jpeg(let data):
            (rgb, width, height) = try await rgbOfJpeg(data: data)
        case .png:
            throw "PNG is not supported at the moment"
        }
        var svg = await geometrizeToSvg(rgb: rgb, width: width, height: height, shapeTypes: [.rotatedEllipse], shapeCount: 250)
        // Fix SVG to keep original image size
        let range = svg.range(of: "width=")!.lowerBound ..< svg.range(of: "viewBox=")!.lowerBound
        svg.replaceSubrange(range.relative(to: svg), with: " width=\"\(originalPhotoWidth)\" height=\"\(originalPhotoHeight)\" ")
        return svg
    }
    
    private func rgbOfJpeg(data: Data) async throws -> ([UInt8], width: Int, height: Int) {
        var bytestreamSource = DataBytestreamSource(data: data)
        guard let image: JPEG.Data.Rectangular<JPEG.Common> = try .decompress(stream: &bytestreamSource) else {
            throw "Cannot decompress JPEG data"
        }
        let rgb: [JPEG.RGB] = image.unpack(as: JPEG.RGB.self)
        let (width, height) = image.size
        let data: [UInt8] = rgb.flatMap({ [$0.r, $0.g, $0.b, 255] })
        return (data, width, height)
    }

    private func geometrizeToSvg(rgb: [UInt8], width: Int, height: Int, shapeTypes: Set<ShapeType>, shapeCount: Int) async -> String {

        let targetBitmap = Bitmap(width: width, height: height, data: rgb)

        let shapeCount: Int = shapeCount

        let runnerOptions = ImageRunnerOptions(
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

        var runner = ImageRunner(targetBitmap: targetBitmap)

        var shapeData: [ShapeResult] = []

        // Hack to add a single background rectangle as the initial shape
        let rect = Rectangle(
            canvasBoundsProvider: { Bounds(xMin: 0, xMax: targetBitmap.width, yMin: 0, yMax: targetBitmap.height) },
            x1: 0, y1: 0, x2: Double(targetBitmap.width), y2: Double(targetBitmap.height)
        )
        shapeData.append(ShapeResult(score: 0, color: targetBitmap.averageColor(), shape: rect))

        var counter = 0
        while shapeData.count <= shapeCount /* Here set count of shapes final image should have. Remember background is the first shape. */ {
            print("Step \(counter)", terminator: "")
            let shapes = runner.step(options: runnerOptions, shapeCreator: nil, energyFunction: defaultEnergyFunction, addShapePrecondition: defaultAddShapePrecondition)
            if shapes.isEmpty {
                print(", no shapes added.", terminator: "")
            } else {
                print(", \(shapes.map(\.shape).map(\.description).joined(separator: ", ")) added.", terminator: "")
            }
            print(" Total count of shapes \(shapeData.count ).")
            shapeData.append(contentsOf: shapes)
            counter += 1
        }

        let svg = SVGExporter().export(data: shapeData, width: width, height: height)

        return svg
    }

}
