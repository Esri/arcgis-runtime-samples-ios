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

class ExtrudeGraphicsViewController: UIViewController {

    @IBOutlet var sceneView:AGSSceneView!
    
    private var graphicsOverlay: AGSGraphicsOverlay!
    
    private let cameraStartingPoint = AGSPoint(x: 83, y: 28.4, z: 20000, spatialReference: AGSSpatialReference.wgs84())
    private let squareSize:Double = 0.01
    private let spacing:Double = 0.01
    private let maxHeight = 10000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ExtrudeGraphicsViewController"]
        
        //initialize scene with topographic basemap
        let scene = AGSScene(basemap: .topographic())
        //assign scene to the scene view
        self.sceneView.scene = scene
        
        //set the viewpoint camera
        let camera = AGSCamera(location: self.cameraStartingPoint, heading: 10, pitch: 70, roll: 0)
        self.sceneView.setViewpointCamera(camera)
        
        //add graphics overlay
        self.graphicsOverlay = AGSGraphicsOverlay()
        self.graphicsOverlay.sceneProperties?.surfacePlacement = .draped
        self.sceneView.graphicsOverlays.add(self.graphicsOverlay)
        
        //simple renderer with extrusion property
        let renderer = AGSSimpleRenderer()
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .white, width: 1)
        renderer.symbol = AGSSimpleFillSymbol(style: .solid, color: .primaryBlue, outline: lineSymbol)
        renderer.sceneProperties?.extrusionMode = .baseHeight
        renderer.sceneProperties?.extrusionExpression = "[height]"
        self.graphicsOverlay.renderer = renderer
        
        // add base surface for elevation data
        let surface = AGSSurface()
        /// The url of the Terrain 3D ArcGIS REST Service.
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        //add the graphics
        self.addGraphics()
    }
    
    private func addGraphics() {
        //starting point
        let x = self.cameraStartingPoint.x - 0.01
        let y = self.cameraStartingPoint.y + 0.25
        
        //creating a grid of polygon graphics
        for i in 0...6 {
            for j in 0...4 {
                let polygon = self.polygonForStartingPoint(AGSPoint(x: x + Double(i) * (squareSize + spacing), y: y + Double(j) * (squareSize + spacing), spatialReference: nil))
                self.addGraphicForPolygon(polygon)
            }
        }
    }
    
    //the function returns a polygon starting at the given point
    //with size equal to squareSize
    private func polygonForStartingPoint(_ point:AGSPoint) -> AGSPolygon {
        let polygon = AGSPolygonBuilder(spatialReference: AGSSpatialReference.wgs84())
        polygon.addPointWith(x: point.x, y: point.y)
        polygon.addPointWith(x: point.x, y: point.y+squareSize)
        polygon.addPointWith(x: point.x + squareSize, y: point.y + squareSize)
        polygon.addPointWith(x: point.x + squareSize, y: point.y)
        return polygon.toGeometry()
    }
    
    //add a graphic to the graphics overlay for the given polygon
    private func addGraphicForPolygon(_ polygon:AGSPolygon) {
        
        let rand = arc4random_uniform(UInt32(self.maxHeight))
        
        let graphic = AGSGraphic(geometry: polygon, symbol: nil, attributes: nil)
        graphic.attributes.setValue(rand, forKey: "height")
        self.graphicsOverlay.graphics.add(graphic)
    }

}
