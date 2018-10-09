// Copyright 2018 Esri.
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

import UIKit
import ArcGIS

fileprivate let observerZMin = 20.0
fileprivate let observerZMax = 1500.0

class LineOfSightGeoElementViewController: UIViewController {
    
    @IBOutlet weak var sceneView: AGSSceneView!

    @IBOutlet weak var targetVisibilityLabel: UILabel!
    @IBOutlet weak var observerZLabel: UILabel!

    @IBOutlet weak var observerZSlider: UISlider!
    @IBOutlet weak var observerZMinLabel: UILabel!
    @IBOutlet weak var observerZMaxLabel: UILabel!

    // properties for setting up and manipulating the scene
    private let scene: AGSScene
    private let overlay: AGSGraphicsOverlay
    private let taxiGraphic: AGSGraphic
    private let observerGraphic: AGSGraphic
    private let lineOfSight: AGSGeoElementLineOfSight

    // locations used in the sample
    private let observerPoint = AGSPoint(x: -73.984988, y: 40.748131, z: observerZMin, spatialReference: .wgs84())

    private let streetIntersectionLocations = [
        AGSPoint(x: -73.985068, y: 40.747786, spatialReference: .wgs84()),
        AGSPoint(x: -73.983452, y: 40.747091, spatialReference: .wgs84()),
        AGSPoint(x: -73.982961, y: 40.747762, spatialReference: .wgs84()),
        AGSPoint(x: -73.984513, y: 40.748469, spatialReference: .wgs84())
    ]

    // handle onto any line of sight KVO observer
    private var losObserver:NSKeyValueObservation?

    private var initialViewpointCenter: AGSPoint {
        // If possible, find the middle of the block that the taxi will drive around, or else focus on the observer
        return AGSGeometryEngine.unionGeometries(streetIntersectionLocations)?.extent.center ?? observerPoint
    }

    required init?(coder aDecoder: NSCoder) {
        // ====================================
        // set up the scene, layers and overlay
        // ====================================

        // initialize the scene with an imagery basemap
        scene = AGSScene(basemap: .imageryWithLabels())

        /// The url of the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        // initialize the elevation source and add it to the base surface of the scene
        let elevationSrc = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        scene.baseSurface?.elevationSources.append(elevationSrc)

        /// The url of a scene service for buildings in New York, U.S.
        let newYorkBuildingsServiceURL = URL(string: "https://tiles.arcgis.com/tiles/z2tnIkrLQ2BRzr6P/arcgis/rest/services/New_York_LoD2_3D_Buildings/SceneServer/layers/0")!
        // add some buildings to the scene
        let sceneLayer = AGSArcGISSceneLayer(url: newYorkBuildingsServiceURL)
        scene.operationalLayers.add(sceneLayer)

        // initialize a graphics overlay
        overlay = AGSGraphicsOverlay()
        overlay.sceneProperties = AGSLayerSceneProperties(surfacePlacement: .relative)


        // =====================================================
        // initialize two graphics for both display and analysis
        // =====================================================

        // initialize the taxi graphic
        let taxiSymbol = AGSModelSceneSymbol(name: "dolmus", extension: "3ds", scale: 1)
        taxiSymbol.anchorPosition = .bottom
        taxiGraphic = AGSGraphic(geometry: streetIntersectionLocations[streetIntersectionLocations.startIndex], symbol: taxiSymbol, attributes: nil)

        // initialize the observer graphic
        let observerSymbol = AGSSimpleMarkerSceneSymbol(style: .sphere, color: .red, height: 10, width: 10, depth: 10, anchorPosition: .center)
        observerGraphic = AGSGraphic(geometry: observerPoint, symbol: observerSymbol, attributes: nil)


        // ================
        // use the graphics
        // ================

        // add the taxi and observer to the graphics overlay
        overlay.graphics.addObjects(from: [observerGraphic, taxiGraphic])

        // initialize the line of sight analysis between the observer and taxi
        lineOfSight = AGSGeoElementLineOfSight(observerGeoElement: observerGraphic, targetGeoElement: taxiGraphic)

        super.init(coder: aDecoder)

        // set the initial viewpoint
        scene.initialViewpoint = AGSViewpoint(center: initialViewpointCenter, scale: 6000)

        // default to a line of sight target offset of 1.5m above ground
        lineOfSight.targetOffsetZ = 1.5
        
        // let's examine the 3D model symbol to see if we can determine a better height
        taxiSymbol.load { [weak self] error in
            guard error == nil else {
                print("Error loading the taxi symbol: \(error!.localizedDescription)")
                return
            }
            // use the model's height as the line of sight target offset above ground
            self?.lineOfSight.targetOffsetZ = taxiSymbol.height
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["LineOfSightGeoElementViewController"]

        // assign the scene to the scene view
        sceneView.scene = scene

        // Add a graphics overlay for the taxi and observer
        sceneView.graphicsOverlays.add(overlay)

        // create an analysis overlay using a single Line of Sight and add it to the scene view
        let analysisOverlay = AGSAnalysisOverlay()
        analysisOverlay.analyses.add(lineOfSight)
        sceneView.analysisOverlays.add(analysisOverlay)

        // update the UI if the Line of Sight analysis result changes
        losObserver = lineOfSight.observe(\.targetVisibility, options: .new) { [weak self] (losAnalysis, _) in
            DispatchQueue.main.async {
                self?.updateLineOfSightVisibilityLabel(visibility: losAnalysis.targetVisibility)
            }
        }

        // initialize the observer z slider
        observerZSlider.minimumValue = Float(observerZMin)
        observerZSlider.maximumValue = Float(observerZMax)

        observerZMinLabel.text = getFormattedString(z: observerZMin)
        observerZMaxLabel.text = getFormattedString(z: observerZMax)
    }

    // update the observer height when the slider is moved
    @IBAction func observerHeightChanged(_ observerZSlider: UISlider) {
        if let oldLocation = observerGraphic.geometry as? AGSPoint,
            let newLocation = AGSGeometryEngine.geometry(bySettingZ: Double(observerZSlider.value), in: oldLocation) as? AGSPoint {
            observerGraphic.geometry = newLocation
            updateObserverZLabel()
        }
    }

    // Clean up when done with the sample
    deinit {
        losObserver?.invalidate()
    }



    // start and stop animation
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startAnimation()

        // set the line width (default 1.0). This setting is applied to all line of sight analysis in the view
        AGSLineOfSight.setLineWidth(2.0)

        // update the ui
        observerZSlider.value = Float(observerPoint.z)
        updateObserverZLabel()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        animationTimer?.invalidate()
    }

    

    // current line of sight status
    private func updateLineOfSightVisibilityLabel(visibility: AGSLineOfSightTargetVisibility) {
        switch visibility {
        case .obstructed:
            targetVisibilityLabel.text = "Obstructed"
            taxiGraphic.isSelected = false
        case .visible:
            targetVisibilityLabel.text = "Visible"
            taxiGraphic.isSelected = true
        case .unknown:
            targetVisibilityLabel.text = "Unknown"
            taxiGraphic.isSelected = false
        }
    }

    private func updateObserverZLabel() {
        observerZLabel.text = {
            guard let observerLocation = observerGraphic.geometry as? AGSPoint, observerLocation.hasZ else {
                return "Unknown"
            }
            return getFormattedString(z: observerLocation.z)
        }()
    }



    // Track animation progress
    private var animationProgess = (frameIndex: 0, pointIndex: 0)
    private var animationTimer:Timer?
    private let framesPerSegment = 150

    private func startAnimation() {
        // Kick off a timer
        animationProgess = (frameIndex: 0, pointIndex: streetIntersectionLocations.startIndex)
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            self?.performAnimationFrame()
        }
    }

    private func performAnimationFrame() {
        animationProgess.frameIndex += 1

        // See if we've reached the next intersection.
        if animationProgess.frameIndex == self.framesPerSegment {
            // Move to the next segment
            animationProgess.frameIndex = 0
            animationProgess.pointIndex += 1
            // And if we've visited all intersections, start at the beginning again
            if animationProgess.pointIndex == streetIntersectionLocations.endIndex {
                animationProgess.pointIndex = streetIntersectionLocations.startIndex
            }
        }

        // Get the current taxi position between two intersections as well as its heading
        let startPoint = streetIntersectionLocations[animationProgess.pointIndex]
        let endPoint = streetIntersectionLocations[(animationProgess.pointIndex + 1) % streetIntersectionLocations.endIndex]
        let progress = Double(animationProgess.frameIndex) / Double(framesPerSegment)
        let (animationPoint, heading) = interpolatedPoint(firstPoint: startPoint, secondPoint: endPoint, progress: progress)

        // Update the taxi graphic's potision and heading
        taxiGraphic.geometry = animationPoint
        (taxiGraphic.symbol as? AGSModelSceneSymbol)?.heading = heading
    }

    
    
    // Formatting z values for locale
    private let zValuesFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        formatter.numberFormatter.roundingMode = .down
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    private func getFormattedString(z value:Double) -> String {
        return zValuesFormatter.string(from: Measurement<UnitLength>(value: value, unit: .meters))
    }
}

fileprivate func interpolatedPoint(firstPoint: AGSPoint, secondPoint:AGSPoint, progress:Double) -> (AGSPoint, Double) {
    // Use the geometry engine to calculate the heading between point 1 and 2
    let geResult = AGSGeometryEngine.geodeticDistanceBetweenPoint1(firstPoint, point2: secondPoint,
                                                                   distanceUnit: .meters(),
                                                                   azimuthUnit: .degrees(),
                                                                   curveType: .geodesic)
    let heading = geResult?.azimuth1 ?? 0

    // calculate the point representing progress towards the next point (cartesian calculation works fine at this scale)
    let diff = (x: (secondPoint.x - firstPoint.x) * progress,
                y: (secondPoint.y - firstPoint.y) * progress,
                z: (secondPoint.z - firstPoint.z) * progress)

    return (AGSPoint(x: firstPoint.x + diff.x,
                     y: firstPoint.y + diff.y,
                     z: firstPoint.z + diff.z,
                     spatialReference: firstPoint.spatialReference), heading)
}
