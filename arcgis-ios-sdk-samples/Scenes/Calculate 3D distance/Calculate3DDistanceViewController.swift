//
// Copyright © 2018 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import ArcGIS

/// The range of possible `x` values for the location of the symbols.
private let rangeX = -120.05859621653715 ... -77.69531409620706
/// The speed of the animation in coordinate values per second.
private let animationSpeed = 1.0
/// The duration of the animation (in one direction).
private var animationDuration: TimeInterval {
    return (rangeX.upperBound - rangeX.lowerBound) / animationSpeed
}

/// A view controller that manages the interface of the Calculate 3D Distance
/// sample.
class Calculate3DDistanceViewController: UIViewController {
    /// The scene view managed by the view controller.
    @IBOutlet weak var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene()
            sceneView.graphicsOverlays.add(makeGraphicsOverlay())
            sceneView.setViewpointCamera(AGSCamera(latitude: 39, longitude: -101, altitude: 10_000_000, heading: 10, pitch: 0, roll: 0))
        }
    }
    /// The label that shows the distance between the two graphics.
    @IBOutlet weak var distanceLabel: UILabel! {
        didSet {
            updateDistanceLabel()
        }
    }
    /// The formatter for converting distance measurements to a string.
    let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()
    
    /// The display link used to animate the movement of the graphics.
    private var displayLink: CADisplayLink?
    /// The observation of the scene view's draw status.
    private var drawStatusObservation: NSKeyValueObservation?
    
    /// A red triangle graphic.
    let redGraphic: AGSGraphic = {
        let point = AGSPoint(x: rangeX.upperBound, y: 40.25390707699415, z: 900, spatialReference: .wgs84())
        let symbol = AGSSimpleMarkerSymbol(style: .triangle, color: .red, size: 20)
        return AGSGraphic(geometry: point, symbol: symbol)
    }()
    /// The function that determines the x-coordinate of the location of the
    /// red graphic.
    let redPositionFunction = AbsoluteValueFunction(
        vertex: Point(x: animationDuration, y: rangeX.upperBound),
        point: Point(x: 0, y: rangeX.lowerBound)
    )
    /// A green triangle graphic.
    let greenGraphic: AGSGraphic = {
        let point = AGSPoint(x: rangeX.lowerBound, y: 38.847657048103514, z: 1_000, spatialReference: .wgs84())
        let symbol = AGSSimpleMarkerSymbol(style: .triangle, color: .green, size: 20)
        return AGSGraphic(geometry: point, symbol: symbol)
    }()
    /// The function that determines the x-coordinate of the location of the
    /// green graphic.
    let greenPositionFunction = AbsoluteValueFunction(
        vertex: Point(x: animationDuration, y: rangeX.lowerBound),
        point: Point(x: 0, y: rangeX.upperBound)
    )
    
    /// Creates a scene.
    ///
    /// - Returns: A new `AGSScene` object.
    func makeScene() -> AGSScene {
        let elevationSourceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationSourceURL)
        
        let surface = AGSSurface()
        surface.elevationSources = [elevationSource]
        
        let scene = AGSScene(basemapType: .imagery)
        scene.baseSurface = surface
        return scene
    }
    
    /// Creates a graphics overlay with two grahpics.
    ///
    /// - Returns: A new `AGSGraphicsOverlay` object.
    func makeGraphicsOverlay() -> AGSGraphicsOverlay {
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.graphics.addObjects(from: [redGraphic, greenGraphic])
        graphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        return graphicsOverlay
    }
    
    /// Starts animating the graphics. Animation will continue until
    /// `stopAnimatingGraphics()` is called.
    func startAnimatingGraphics() {
        // Create the display link if it doesn't exist yet.
        if displayLink == nil {
            let displayLink = CADisplayLink(target: self, selector: #selector(self.updateGraphics(_:)))
            displayLink.preferredFramesPerSecond = 15
            displayLink.add(to: .current, forMode: .common)
            self.displayLink = displayLink
        }
        displayLink?.isPaused = false
    }
    
    /// Stops animating the graphics.
    func stopAnimatingGraphics() {
        displayLink?.isPaused = true
    }
    
    /// Updates the position of the graphics.
    ///
    /// - Parameter sender: The display link driving the animation.
    @objc
    func updateGraphics(_ sender: CADisplayLink) {
        let duration = TimeInterval((rangeX.upperBound - rangeX.lowerBound) / animationSpeed)
        let time = sender.timestamp.truncatingRemainder(dividingBy: duration * 2)
        
        let redPoint = redGraphic.geometry as! AGSPoint
        redGraphic.geometry = AGSPoint(x: redPositionFunction.apply(to: time), y: redPoint.y, z: redPoint.z, spatialReference: redPoint.spatialReference)
        (redGraphic.symbol as! AGSSimpleMarkerSymbol).angle = time >= duration ? 180 : 0
        
        let greenPoint = greenGraphic.geometry as! AGSPoint
        greenGraphic.geometry = AGSPoint(x: greenPositionFunction.apply(to: time), y: greenPoint.y, z: greenPoint.z, spatialReference: greenPoint.spatialReference)
        (greenGraphic.symbol as! AGSSimpleMarkerSymbol).angle = time >= duration ? 210 : 30
        
        updateDistanceLabel()
    }
    
    /// Updates the distance label.
    func updateDistanceLabel() {
        let redPoint = redGraphic.geometry as! AGSPoint
        let greenPoint = greenGraphic.geometry as! AGSPoint
        
        let spherical1 = simd_double3(redPoint.x, redPoint.y, redPoint.z)
        let spherical2 = simd_double3(greenPoint.x, greenPoint.y, greenPoint.z)
        
        let cartesian1 = cartesian(fromSpherical: spherical1)
        let cartesian2 = cartesian(fromSpherical: spherical2)
        
        let distance = Measurement(
            value: simd_distance(cartesian1, cartesian2),
            unit: UnitLength.meters
        )
        distanceLabel.text = String(format: "Distance: %@", measurementFormatter.string(from: distance))
    }
    
    /// Converts a spherical point to a cartesian point.
    ///
    /// - Parameter spherical: A point in the spherical coordinate system.
    /// - Returns: A point in the cartesian coordinate system.
    func cartesian(fromSpherical spherical: simd_double3) -> simd_double3 {
        let earthRadius = Measurement(value: 6_371_000, unit: UnitLength.meters)
        
        let latitude = Measurement<UnitAngle>(value: spherical.x, unit: .degrees)
            .converted(to: .radians)
        let longitude = Measurement<UnitAngle>(value: spherical.y, unit: .degrees)
            .converted(to: .radians)
        let radius = earthRadius + Measurement(value: spherical.z, unit: .meters)
        return simd_double3(
            earthRadius.value * cos(latitude.value) * cos(longitude.value),
            earthRadius.value * cos(latitude.value) * sin(longitude.value),
            radius.value * sin(latitude.value)
        )
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["Calculate3DDistanceViewController"]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        drawStatusObservation = sceneView.observe(\.drawStatus, options: .initial) { [weak self] (sceneView, _) in
            DispatchQueue.main.async {
                guard sceneView.drawStatus == .completed,
                    let self = self else {
                        return
                }
                // Start the animation.
                self.startAnimatingGraphics()
                self.drawStatusObservation = nil
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopAnimatingGraphics()
    }
}

/// A point in a two-dimensional coordinate system.
struct Point: Equatable {
    /// The x-coordinate of the point.
    var x: Double
    /// The y-coordinate of the point.
    var y: Double
}

/// A function of a single variable.
protocol Function {
    /// Applies the function to a given value.
    ///
    /// - Parameter x: A value.
    /// - Returns: The result of applying the function to `x`.
    func apply(to x: Double) -> Double
}

/// An absolute value function of the form y=a|x-h|+k.
struct AbsoluteValueFunction: Function {
    var a: Double
    var h: Double
    var k: Double
    
    func apply(to x: Double) -> Double {
        return a * (x - h).magnitude + k
    }
}

extension AbsoluteValueFunction {
    /// Creates an absolute value function with the given vertex and a given
    /// point.
    ///
    /// - Parameters:
    ///   - vertex: The vertex of the function.
    ///   - point: A known point, other than the vertex.
    /// - Precondition: `vertex != point`
    init(vertex: Point, point: Point) {
        precondition(vertex != point)
        let a = (point.y - vertex.y) / (point.x - vertex.x).magnitude
        self.init(a: a, h: vertex.x, k: vertex.y)
    }
}
