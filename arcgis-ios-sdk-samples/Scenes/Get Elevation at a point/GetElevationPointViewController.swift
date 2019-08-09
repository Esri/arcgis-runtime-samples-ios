// Copyright 2019 Esri.
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

class GetElevationPointViewController: UIViewController {
    @IBOutlet weak var sceneView: AGSSceneView! {
        didSet {
            // Initialize a scene.
            sceneView.scene = makeScene()
            
            // Set scene's viewpoint.
            let camera = AGSCamera(latitude: 28.42, longitude: 83.9, altitude: 10000.0, heading: 10.0, pitch: 80.0, roll: 0.0)
            sceneView.setViewpointCamera(camera)
            
            makeGraphics()
        }
    }
    
    func makeScene() -> AGSScene {
        let scene = AGSScene(basemapType: .imageryWithLabels)
        
        let surface = AGSSurface()
        // Create raster elevation source.
        let elevationURL = URL(string: "http://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationURL!)
        
        // Add a raster source to the surface.
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        return scene
    }
    
    private let graphicsOverlay = AGSGraphicsOverlay()
    
    let elevationLineSymbol = AGSSimpleLineSymbol(style: .solid, color: .red, width: 3.0)
    let polylineGraphic = AGSGraphic()
    polylineGraphic.symbol = elevationLineSymbol
    
    //make graphics
    private func makeGraphics() {
        graphicsOverlay.renderingMode = AGSGraphicsRenderingMode.dynamic
//        graphicsOverlay.sceneProperties?.surfacePlacement = AGSLayerSceneProperties(surfacePlacement: .relative)
        sceneView.graphicsOverlays.add(graphicsOverlay)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GetElevationPointViewController"]
    }
}

// MARK: - AGSGeoViewTouchDelegate
extension GetElevationPointViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        let relativeSurfacePoint = sceneView.screen(toBaseSurface: screenPoint)
        if relativeSurfacePoint != nil {
            graphicsOverlay.clearSelection()
            let polylineBuilder = AGSPolylineBuilder(spatialReference: relativeSurfacePoint.spatialReference)
            let baseOfPolyline = AGSPoint(x: relativeSurfacePoint.x, y: relativeSurfacePoint.y, spatialReference: AGSSpatialReference(wkid: 0))
            polylineBuilder.add(baseOfPolyline)
            let topOfPolyline = AGSPoint(x: baseOfPolyline.x, y: baseOfPolyline.y, spatialReference: AGSSpatialReference(wkid: 750))
            polylineBuilder.add(topOfPolyline)
            let markerPolyline = polylineBuilder.toGeometry()
            polylineGraphic.geometry = markerPolyline
            graphicsOverlay.graphics.add(polylineGraphic)
            
            // Get the surface elevation at the surface point.
            self.sceneView.scene?.baseSurface!.elevation(for: relativeSurfacePoint) { (double: Double, error: Error?) in
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    let elevation = double
                    
                    
                }
            }
        }
        
    }
}
