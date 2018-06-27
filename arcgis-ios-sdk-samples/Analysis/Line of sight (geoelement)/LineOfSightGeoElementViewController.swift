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

    private var lineOfSight: AGSGeoElementLineOfSight? {
        willSet {
            sceneView.analysisOverlays.removeAllObjects()
        }
        didSet {
            if let lineOfSight = lineOfSight {
                // create an analysis overlay using a single Line of Sight and add it to the scene view
                let analysisOverlay = AGSAnalysisOverlay()
                analysisOverlay.analyses.add(lineOfSight)
                sceneView.analysisOverlays.add(analysisOverlay)
            }
        }
    }

    // locations used in the sample
    private let observerPoint = AGSPoint(x: -73.984988, y: 40.748131, z: 20, spatialReference: AGSSpatialReference.wgs84())

    private let streetIntersectionLocations:[AGSPoint] = [
        AGSPoint(x: -73.985068, y: 40.747786, spatialReference: AGSSpatialReference.wgs84()),
        AGSPoint(x: -73.983452, y: 40.747091, spatialReference: AGSSpatialReference.wgs84()),
        AGSPoint(x: -73.982961, y: 40.747762, spatialReference: AGSSpatialReference.wgs84()),
        AGSPoint(x: -73.984513, y: 40.748469, spatialReference: AGSSpatialReference.wgs84())
    ]

    // handle onto any line of sight KVO observer
    private var losObserver:NSKeyValueObservation?

    private var initialViewpointCenter:AGSPoint {
        // If possible, find the middle of the block that the taxi will drive around, or else focus on the observer
        return AGSGeometryEngine.unionGeometries(streetIntersectionLocations)?.extent.center ?? observerPoint
    }

    required init?(coder aDecoder: NSCoder) {
        // initialize the scene with an imagery basemap
        scene = AGSScene(basemap: AGSBasemap.imageryWithLabels())

        // initialize the elevation source with the service URL and add it to the base surface of the scene
        let elevationSrc = AGSArcGISTiledElevationSource(url: .worldElevationService)
        scene.baseSurface?.elevationSources.append(elevationSrc)

        // add some buildings to the scene
        let sceneLayer = AGSArcGISSceneLayer(url: .newYorkBuildingsService)
        scene.operationalLayers.add(sceneLayer)

        // initialize the taxi graphic
        let taxiSymbol = AGSModelSceneSymbol(name: "dolmus", extension: "3ds", scale: 1)
        taxiSymbol.anchorPosition = .bottom
        taxiGraphic = AGSGraphic(geometry: streetIntersectionLocations[0], symbol: taxiSymbol, attributes: nil)

        // initialize the observer graphic
        let observerSymbol = AGSSimpleMarkerSceneSymbol(style: .sphere, color: .red, height: 10, width: 10, depth: 10, anchorPosition: .center)
        observerGraphic = AGSGraphic(geometry: observerPoint, symbol: observerSymbol, attributes: nil)

        // initialize the graphics overlay
        overlay = AGSGraphicsOverlay()
        overlay.sceneProperties = AGSLayerSceneProperties(surfacePlacement: .relative)

        // add the taxi and observer to the graphics overlay
        overlay.graphics.addObjects(from: [observerGraphic, taxiGraphic])

        super.init(coder: aDecoder)

        // set the viewpoint specified by the camera position
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

        // initialize the line of sight analysis
        lineOfSight = AGSGeoElementLineOfSight(observerGeoElement: observerGraphic, targetGeoElement: taxiGraphic)

        // update the UI if the Line of Sight analysis result changes
        losObserver = lineOfSight?.observe(\.targetVisibility, options: [.new], changeHandler: { (losAnalysis, change) in
            DispatchQueue.main.async { [weak self] in
                switch losAnalysis.targetVisibility {
                case .obstructed:
                    self?.statusLabel.text = "Obstructed"
                    self?.taxiGraphic.isSelected = false
                case .visible:
                    self?.statusLabel.text = "Visible"
                    self?.taxiGraphic.isSelected = true
                case .unknown:
                    self?.statusLabel.text = "Unknown"
                    self?.taxiGraphic.isSelected = false
                }
            }
        })

        // set the line width (default 1.0). This setting is applied to all line of sight analysis in the view
        AGSLineOfSight.setLineWidth(2.0)

        heightSlider.value = Float(observerPoint.z)
    }

    // start and stop animation
    override func viewWillAppear(_ animated: Bool) {
        startAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
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
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true, block: { [weak self] _ in
            guard let `self` = self else { return }

            self.animationProgess.frameIndex += 1

            // See if we've reached the next intersection.
            if self.animationProgess.frameIndex == self.framesPerSegment {
                // Move to the next segment
                self.animationProgess.frameIndex = 0
                self.animationProgess.pointIndex += 1
                // And if we've visited all intersections, start at the beginning again
                if self.animationProgess.pointIndex == self.streetIntersectionLocations.count {
                    self.animationProgess.pointIndex = 0
                }
            }

            // Get the current taxi position between two intersections as well as its heading
            let startPoint = self.streetIntersectionLocations[self.animationProgess.pointIndex]
            let endPoint = self.streetIntersectionLocations[(self.animationProgess.pointIndex + 1) % self.streetIntersectionLocations.count]
            let progress = Double(self.animationProgess.frameIndex) / Double(self.framesPerSegment)
            let (animationPoint, heading) = interpolatedPoint(firstPoint: startPoint, secondPoint: endPoint, progress: progress)

            // Update the taxi graphic's potision and heading
            self.taxiGraphic.geometry = animationPoint
            (self.taxiGraphic.symbol as? AGSModelSceneSymbol)?.heading = heading
        })
    }
}

fileprivate func interpolatedPoint(firstPoint: AGSPoint, secondPoint:AGSPoint, progress:Double) -> (AGSPoint, Double) {
    let diff = (x: (secondPoint.x - firstPoint.x) * progress,
                y: (secondPoint.y - firstPoint.y) * progress,
                z: (secondPoint.z - firstPoint.z) * progress)

    let geResult = AGSGeometryEngine.geodeticDistanceBetweenPoint1(firstPoint, point2: secondPoint,
                                                                   distanceUnit: AGSLinearUnit.feet(),
                                                                   azimuthUnit: AGSAngularUnit.degrees(),
                                                                   curveType: AGSGeodeticCurveType.geodesic)
    let heading = geResult?.azimuth1 ?? 0

    return (AGSPoint(x: firstPoint.x + diff.x,
                     y: firstPoint.y + diff.y,
                     z: firstPoint.z + diff.z,
                     spatialReference: firstPoint.spatialReference), heading)
}
