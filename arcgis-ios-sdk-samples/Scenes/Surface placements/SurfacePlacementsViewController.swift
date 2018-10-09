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
    /// The scene displayed in the scene view.
    let scene: AGSScene
    
    required init?(coder: NSCoder) {
        scene = AGSScene(basemap: .topographic())
        
        // add base surface for elevation data
        let surface = AGSSurface()
        /// The url of the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        super.init(coder: coder)
    }
    
    /// The scene view managed by the view controller.
    @IBOutlet var sceneView: AGSSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.scene = scene
        
        let camera = AGSCamera(latitude: 53.04, longitude: -4.04, altitude: 1300, heading: 0, pitch: 90, roll: 0)
        self.sceneView.setViewpointCamera(camera)
        
        let graphicsOverlays = [
            makeGraphicsOverlay(surfacePlacement: .draped),
            makeGraphicsOverlay(surfacePlacement: .relative),
            makeGraphicsOverlay(surfacePlacement: .absolute)
        ]
        sceneView.graphicsOverlays.addObjects(from: graphicsOverlays)
        
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SurfacePlacementsViewController"]
    }
    
    /// Creates a graphics overlay for the given surface placement.
    ///
    /// - Parameter surfacePlacement: The surface placement for which to create
    /// a graphics overlay.
    /// - Returns: A new `AGSGraphicsOverlay` object.
    func makeGraphicsOverlay(surfacePlacement: AGSSurfacePlacement) -> AGSGraphicsOverlay {
        let symbols = [
            AGSSimpleMarkerSceneSymbol(style: .sphere, color: .red, height: 50, width: 50, depth: 50, anchorPosition: .center),
            AGSTextSymbol(text: surfacePlacement.title, color: .blue, size: 20, horizontalAlignment: .left, verticalAlignment: .middle)
        ]
        let point = AGSPoint(x: -4.04, y: 53.06, z: 1000, spatialReference: .wgs84())
        let graphics = symbols.map { AGSGraphic(geometry: point, symbol: $0) }
        
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.sceneProperties?.surfacePlacement = surfacePlacement
        graphicsOverlay.graphics.addObjects(from: graphics)
        return graphicsOverlay
    }
}

private extension AGSSurfacePlacement {
    /// The human readable name of the surface placement.
    var title: String {
        switch self {
        case .draped: return "Draped"
        case .relative: return "Relative"
        case .absolute: return "Absolute"
        }
    }
}
