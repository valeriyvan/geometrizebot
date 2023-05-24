import Foundation
import Geometrize

internal func geometrizeToSvg(rgb: [UInt8], width: Int, height: Int) async -> String {
    let targetBitmap = Bitmap(width: width, height: height, data: rgb)

    let shapeCount: Int = 250

    let runnerOptions = ImageRunnerOptions(
        shapeTypes: [.rotatedEllipse],
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
    let rect = Rectangle(x1: 0, y1: 0, x2: Double(targetBitmap.width), y2: Double(targetBitmap.height))
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
    //print(svg)

    return svg
}
