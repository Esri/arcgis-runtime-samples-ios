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

class LineOfSightGeoElementViewController: UIViewController {
    
    @IBOutlet weak var sceneView: AGSSceneView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var heightSlider: UISlider!

    // properties for setting up and manipulating the scene
    let scene:AGSScene
    let overlay:AGSGraphicsOverlay
    let taxiGraphic:AGSGraphic
    let observerGraphic:AGSGraphic
    let lineOfSight: AGSGeoElementLineOfSight

    // locations used in the sample
    private let observerPoint = AGSPoint(x: -73.984988, y: 40.748131, z: 20, spatialReference: .wgs84())

    private let streetIntersectionLocations = [
        AGSPoint(x: -73.985068, y: 40.747786, spatialReference: .wgs84()),
        AGSPoint(x: -73.983452, y: 40.747091, spatialReference: .wgs84()),
        AGSPoint(x: -73.982961, y: 40.747762, spatialReference: .wgs84()),
        AGSPoint(x: -73.984513, y: 40.748469, spatialReference: .wgs84())
    ]

    // handle onto any line of sight KVO observer
    private var losObserver:NSKeyValueObservation?

    private var initialViewpointCenter:AGSPoint {
        // If possible, find the middle of the block that the taxi will drive around, or else focus on the observer
        return AGSGeometryEngine.unionGeometries(streetIntersectionLocations)?.extent.center ?? observerPoint
    }

    required init?(coder aDecoder: NSCoder) {
        // ====================================
        // set up the scene, layers and overlay
        // ====================================

        // initialize the scene with an imagery basemap
        scene = AGSScene(basemap: AGSBasemap.imageryWithLabels())

        // initialize the elevation source and add it to the base surface of the scene
        let elevationSrc = AGSArcGISTiledElevationSource(url: .worldElevationService)
        scene.baseSurface?.elevationSources.append(elevationSrc)

        // add some buildings to the scene
        let sceneLayer = AGSArcGISSceneLayer(url: .newYorkBuildingsService)
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
        losObserver = lineOfSight.observe(\.targetVisibility, options: .new) { (losAnalysis, _) in
            DispatchQueue.main.async { [weak self] in
                self?.updateForLineOfSightTargetVisibility(visibility: losAnalysis.targetVisibility)
            }
        }
    }

    private func updateForLineOfSightTargetVisibility(visibility:AGSLineOfSightTargetVisibility) {
        switch visibility {
        case .obstructed:
            statusLabel.text = "Obstructed"
            taxiGraphic.isSelected = false
        case .visible:
            statusLabel.text = "Visible"
            taxiGraphic.isSelected = true
        case .unknown:
            statusLabel.text = "Unknown"
            taxiGraphic.isSelected = false
        }
    }

    // start and stop animation
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        startAnimation()

        // set the line width (default 1.0). This setting is applied to all line of sight analysis in the view
        AGSLineOfSight.setLineWidth(2.0)

        heightSlider.value = Float(observerPoint.z)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        animationTimer?.invalidate()
    }

    // update the observer height when the slider is moved
    @IBAction func observerHeightChanged(_ sender: UISlider) {
        if let oldLocation = observerGraphic.geometry as? AGSPoint,
            let newLocation = AGSGeometryEngine.geometry(bySettingZ: Double(sender.value), in: oldLocation) as? AGSPoint {
            observerGraphic.geometry = newLocation
        }
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
