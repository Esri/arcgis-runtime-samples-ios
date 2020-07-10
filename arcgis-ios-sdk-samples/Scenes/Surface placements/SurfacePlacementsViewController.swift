//
// Copyright 2016 Esri.
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

/// A view controller that manages the interface of the Surface Placements
/// sample.
class SurfacePlacementsViewController: UIViewController {
    // MARK: Instance properties
    
    /// A label to show the value of the slider.
    @IBOutlet weak var zValueLabel: UILabel!
    /// The slider to change z-value of `AGSPoint` geometries, from 0 to 140 in meters.
    @IBOutlet weak var zValueSlider: UISlider!
    /// The segmented control to toggle the visibility of two draped mode graphics overlays.
    @IBOutlet weak var drapedModeSegmentedControl: UISegmentedControl!
    
    /// The scene view managed by the view controller.
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene()
            sceneView.setViewpointCamera(AGSCamera(latitude: 48.3889, longitude: -4.4595, altitude: 80, heading: 330, pitch: 97, roll: 0))
            // Add graphics overlays of different surface placement modes to the scene.
            overlaysBySurfacePlacement[.drapedBillboarded] = makeGraphicsOverlay(surfacePlacement: .drapedBillboarded)
            overlaysBySurfacePlacement[.drapedFlat] = makeGraphicsOverlay(surfacePlacement: .drapedFlat)
            overlaysBySurfacePlacement[.relative] = makeGraphicsOverlay(surfacePlacement: .relative)
            overlaysBySurfacePlacement[.relativeToScene] = makeGraphicsOverlay(surfacePlacement: .relativeToScene, offset: 2e-4)
            overlaysBySurfacePlacement[.absolute] = makeGraphicsOverlay(surfacePlacement: .absolute)
            sceneView.graphicsOverlays.addObjects(from: overlaysBySurfacePlacement.map { $0.value })
        }
    }
    
    /// A dictionary for graphics overlays of different surface placement modes.
    var overlaysBySurfacePlacement = [AGSSurfacePlacement: AGSGraphicsOverlay]()
    /// A formatter to format z-value strings.
    let zValueFormatter: LengthFormatter = {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()
    
    // MARK: - Actions
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        // Toggle the visibility of two draped mode graphics overlays respectively.
        let isDrapedFlat = sender.selectedSegmentIndex == 1
        overlaysBySurfacePlacement[.drapedFlat]!.isVisible = isDrapedFlat
        overlaysBySurfacePlacement[.drapedBillboarded]!.isVisible = !isDrapedFlat
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let zValue = Double(sender.value)
        zValueLabel.text = zValueFormatter.string(fromValue: zValue, unit: .meter)
        // Set the z-value of each geometry of surface placement graphics.
        overlaysBySurfacePlacement.values.forEach { graphicOverlay in
            graphicOverlay.graphics.forEach { graphic in
                let currentGraphic = graphic as! AGSGraphic
                let originalPoint = currentGraphic.geometry as! AGSPoint
                let newPoint = AGSGeometryEngine.geometry(bySettingZ: zValue, in: originalPoint) as! AGSPoint
                currentGraphic.geometry = newPoint
            }
        }
    }
    
    // MARK: Initialize scene and make graphics overlays
    
    /// Create a scene.
    ///
    /// - Returns: A new `AGSScene` object.
    func makeScene() -> AGSScene {
        let scene = AGSScene(basemap: .imagery())
        // Add a base surface for elevation data.
        let surface = AGSSurface()
        // Create elevation source from the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        surface.elevationSources.append(elevationSource)
        // Create scene layer from the Brest, France scene server.
        let sceneServiceURL = URL(string: "https://tiles.arcgis.com/tiles/P3ePLMYs2RVChkJx/arcgis/rest/services/Buildings_Brest/SceneServer")!
        let sceneLayer = AGSArcGISSceneLayer(url: sceneServiceURL)
        scene.baseSurface = surface
        scene.operationalLayers.add(sceneLayer)
        return scene
    }
    
    /// Create a graphics overlay for the given surface placement.
    ///
    /// - Parameters:
    ///   - surfacePlacement: The surface placement for which to create a graphics overlay.
    ///   - offset: A offset added to x and y of the geometry, to better differentiate geometries.
    /// - Returns: A new `AGSGraphicsOverlay` object.
    func makeGraphicsOverlay(surfacePlacement: AGSSurfacePlacement, offset: Double = 0) -> AGSGraphicsOverlay {
        let markerSymbol = AGSSimpleMarkerSymbol(style: .triangle, color: .red, size: 20)
        let textSymbol = AGSTextSymbol(text: surfacePlacement.title, color: .magenta, size: 20, horizontalAlignment: .left, verticalAlignment: .middle)
        // Add offset to avoid overlapping text and marker.
        textSymbol.offsetY = 20
        let surfaceRelatedPoint = AGSPoint(x: -4.4609257 + offset, y: 48.3903965 + offset, z: 70, spatialReference: .wgs84())
        let graphics = [markerSymbol, textSymbol].map { AGSGraphic(geometry: surfaceRelatedPoint, symbol: $0) }
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.sceneProperties?.surfacePlacement = surfacePlacement
        graphicsOverlay.graphics.addObjects(from: graphics)
        return graphicsOverlay
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SurfacePlacementsViewController"]
        // Initialize the draped mode visibility.
        segmentedControlValueChanged(drapedModeSegmentedControl)
    }
}

private extension AGSSurfacePlacement {
    /// The human readable name of the surface placement.
    var title: String {
        switch self {
        case .drapedBillboarded: return "Draped Billboarded"
        case .absolute: return "Absolute"
        case .relative: return "Relative"
        case .relativeToScene: return "Relative to Scene"
        case .drapedFlat: return "Draped Flat"
        @unknown default: return "Unknown"
        }
    }
}
