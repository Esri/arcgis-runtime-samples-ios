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

class SceneSymbolsViewController: UIViewController {
    @IBOutlet var sceneView: AGSSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SceneSymbolsViewController"]
        
        let scene = AGSScene(basemap: .topographic())
        
        // Add base surface for elevation data.
        let surface = AGSSurface()
        /// The url of the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        sceneView.scene = scene
        
        // Add graphics overlay to the scene view.
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.graphics.addObjects(from: makeGraphics())
        graphicsOverlay.sceneProperties?.surfacePlacement = .absolute
        sceneView.graphicsOverlays.add(graphicsOverlay)
        
        // Set the camera.
        let camera = AGSCamera(latitude: 48.973, longitude: 4.92, altitude: 2082, heading: 60, pitch: 75, roll: 0)
        sceneView.setViewpointCamera(camera)
    }
    
    private func makeGraphics() -> [AGSGraphic] {
        // Coordinates for the first symbol.
        let x = 4.975
        let y = 49.0
        let z = 500.0
        
        // Create symbols for all the available 3D symbols.
        
        let coneSymbol = AGSSimpleMarkerSceneSymbol(style: .cone, color: .random(), height: 200, width: 200, depth: 200, anchorPosition: .center)
        let cubeSymbol = AGSSimpleMarkerSceneSymbol(style: .cube, color: .random(), height: 200, width: 200, depth: 200, anchorPosition: .center)
        let cylinderSymbol = AGSSimpleMarkerSceneSymbol(style: .cylinder, color: .random(), height: 200, width: 200, depth: 200, anchorPosition: .center)
        let diamondSymbol = AGSSimpleMarkerSceneSymbol(style: .diamond, color: .random(), height: 200, width: 200, depth: 200, anchorPosition: .center)
        let sphereSymbol = AGSSimpleMarkerSceneSymbol(style: .sphere, color: .random(), height: 200, width: 200, depth: 200, anchorPosition: .center)
        let tetrahedronSymbol = AGSSimpleMarkerSceneSymbol(style: .tetrahedron, color: .random(), height: 200, width: 200, depth: 200, anchorPosition: .center)
        
        // Create graphics for each symbol.
        let symbols = [coneSymbol, cubeSymbol, cylinderSymbol, diamondSymbol, sphereSymbol, tetrahedronSymbol]
        let graphics = symbols.enumerated().map { (i, symbol) -> AGSGraphic in
            let point = AGSPoint(x: x + 0.01 * Double(i), y: y, z: z, spatialReference: .wgs84())
            return AGSGraphic(geometry: point, symbol: symbol)
        }
        
        return graphics
    }
}

private extension UIColor {
    /// Creates a random color whose red, green, and blue values are in the
    /// range `0...1` and whose alpha value is `1`.
    ///
    /// - Returns: A new `UIColor` object.
    static func random() -> UIColor {
        let range: ClosedRange<CGFloat> = 0...1
        return UIColor(red: .random(in: range), green: .random(in: range), blue: .random(in: range), alpha: 1)
    }
}
