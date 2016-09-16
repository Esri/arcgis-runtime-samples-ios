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

    @IBOutlet var sceneView:AGSSceneView!
    
    private var graphicsOverlay = AGSGraphicsOverlay()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SceneSymbolsViewController"]
        
        let scene = AGSScene(basemap: AGSBasemap.topographicBasemap())
        
        self.sceneView.scene = scene
        
        //set the camera
        let camera = AGSCamera(latitude: 28.97, longitude: 44.933, altitude: 2082, heading: 60, pitch: 75, roll: 0)
        self.sceneView.setViewpointCamera(camera)
        
        // add base surface for elevation data
        let surface = AGSSurface()
        let elevationSource = AGSArcGISTiledElevationSource(URL: NSURL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        //add graphics overlay to the scene view
        self.graphicsOverlay.sceneProperties?.surfacePlacement = .Absolute
        self.sceneView.graphicsOverlays.addObject(graphicsOverlay)
        
        //add graphics
        self.addGraphics()
    }
    
    private func addGraphics() {
        //coordinates for the first symbol
        let x = 44.975
        let y = 29.0
        let z = 500.0
        
        //create symbols for all the available 3D symbols
        var symbols = [AGSSimpleMarkerSceneSymbol]()
        
        let coneSymbol = AGSSimpleMarkerSceneSymbol(style: .Cone, color: self.randColor(), height: 200, width: 200, depth: 200, anchorPosition: .Center)
        
        let cubeSymbol = AGSSimpleMarkerSceneSymbol(style: .Cube, color: self.randColor(), height: 200, width: 200, depth: 200, anchorPosition: .Center)
        
        let cylinderSymbol = AGSSimpleMarkerSceneSymbol(style: .Cylinder, color: self.randColor(), height: 200, width: 200, depth: 200, anchorPosition: .Center)
        
        let diamondSymbol = AGSSimpleMarkerSceneSymbol(style: .Diamond, color: self.randColor(), height: 200, width: 200, depth: 200, anchorPosition: .Center)
        
        let sphereSymbol = AGSSimpleMarkerSceneSymbol(style: .Sphere, color: self.randColor(), height: 200, width: 200, depth: 200, anchorPosition: .Center)
        
        let tetrahedronSymbol = AGSSimpleMarkerSceneSymbol(style: .Tetrahedron, color: self.randColor(), height: 200, width: 200, depth: 200, anchorPosition: .Center)
        
        symbols.appendContentsOf([coneSymbol, cubeSymbol, cylinderSymbol, diamondSymbol, sphereSymbol, tetrahedronSymbol])
        
        //create graphics for each symbol
        var graphics = [AGSGraphic]()
        
        var i = 0
        for symbol in symbols {
            let point = AGSPoint(x: x + 0.01 * Double(i), y: y, z: z, spatialReference: AGSSpatialReference.WGS84())
            let graphic = AGSGraphic(geometry: point, symbol: symbol)
            graphics.append(graphic)
            i = i + 1
        }
        
        //add the graphics to the overlay
        self.graphicsOverlay.graphics.addObjectsFromArray(graphics)
    }
    
    //returns a random color
    private func randColor() -> UIColor {
        return UIColor(red: self.randFloat(), green: self.randFloat(), blue: self.randFloat(), alpha: 1.0)
    }
    
    //returns a CGFloat between 0 and 1
    private func randFloat() -> CGFloat {
        return CGFloat(arc4random() % 256) / 256
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
