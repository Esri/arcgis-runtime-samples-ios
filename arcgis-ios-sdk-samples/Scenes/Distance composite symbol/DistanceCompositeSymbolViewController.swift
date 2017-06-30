//
// Copyright 2017 Esri.
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

class DistanceCompositeSymbolViewController: UIViewController {
    
    @IBOutlet var sceneView:AGSSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DistanceCompositeSymbolViewController"]
        
        //initialize scene with topographic basemap
        let scene = AGSScene(basemap: AGSBasemap.imagery())
        //assign scene to the scene view
        self.sceneView.scene = scene
        
        // add base surface for elevation data
        let surface = AGSSurface()
        let elevationSource = AGSArcGISTiledElevationSource(url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.sceneProperties?.surfacePlacement = .relative
        self.sceneView.graphicsOverlays.add(graphicsOverlay)
        
        // set up the different symbols
        let circleSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10.0)
        
        let coneSymbol = AGSSimpleMarkerSceneSymbol.cone(with: .red, diameter: 200, height: 600)
        coneSymbol.pitch = -90.0
        
        let modelSymbol = AGSModelSceneSymbol(name: "Bristol", extension: "dae", scale: 100.0)
        modelSymbol.load(completion: { [weak self] (error) in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                return
            }
            
            // set up the distance composite symbol
            let compositeSymbol = AGSDistanceCompositeSceneSymbol()
            compositeSymbol.ranges.append(AGSDistanceSymbolRange(symbol: modelSymbol, minDistance: 0, maxDistance: 10000))
            compositeSymbol.ranges.append(AGSDistanceSymbolRange(symbol: coneSymbol, minDistance: 10001, maxDistance: 30000))
            compositeSymbol.ranges.append(AGSDistanceSymbolRange(symbol: circleSymbol, minDistance: 30001, maxDistance: 0))
            
            // create graphic
            let aircraftPosition = AGSPoint(x: -2.708471, y: 56.096575, z: 5000, spatialReference: AGSSpatialReference.wgs84())
            let aircraftGraphic = AGSGraphic(geometry: aircraftPosition, symbol: compositeSymbol, attributes: nil)
            
            // add graphic to graphics overlay
            graphicsOverlay.graphics.add(aircraftGraphic)
            
            // add a camera and initial camera position
            let camera = AGSCamera(lookAt: aircraftPosition, distance: 2000.0, heading: 0.0, pitch: 70.0, roll: 0.0)
            self?.sceneView.setViewpointCamera(camera)
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
