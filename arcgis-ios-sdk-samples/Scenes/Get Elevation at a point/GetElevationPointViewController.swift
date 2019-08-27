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
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            // Initialize a scene.
            sceneView.scene = makeScene()
            
            self.sceneView.touchDelegate = self
            
            // Set scene's viewpoint.
            let camera = AGSCamera(latitude: 28.42, longitude: 83.9, altitude: 10000.0, heading: 10.0, pitch: 80.0, roll: 0.0)
            sceneView.setViewpointCamera(camera)
            
            makeGraphics()
        }
    }
    
    @IBOutlet var elevationPointLabel: UILabel? {
        didSet {
            self.elevationPointLabel?.isHidden = true
            self.elevationPointLabel?.layer.cornerRadius = 10
        }
    }
    
//    @IBOutlet private var controller: ElevationViewController!
    private let graphicsOverlay = AGSGraphicsOverlay()
    
    // Create graphics overlay and add it to scene view.
    private func makeGraphics() {
        graphicsOverlay.renderingMode = AGSGraphicsRenderingMode.dynamic
        graphicsOverlay.sceneProperties?.surfacePlacement = AGSSurfacePlacement.relative
        sceneView.graphicsOverlays.add(graphicsOverlay)
    }
    
    private func makeScene() -> AGSScene {
        let scene = AGSScene(basemapType: .imageryWithLabels)
        
        let surface = AGSSurface()
        // Create an elevation source.
        let elevationURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationURL!)
        
        // Add the elevation source to the surface.
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        return scene
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GetElevationPointViewController", "ElevationViewController"]
    }
}

// MARK: - AGSGeoViewTouchDelegate
extension GetElevationPointViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let relativeSurfacePoint = sceneView?.screen(toBaseSurface: screenPoint) {
            graphicsOverlay.graphics.removeAllObjects()
            dismiss(animated: true)
            
            // Create the symbol at the tapped point.
            let marker = AGSSimpleMarkerSceneSymbol(style: .sphere, color: .red, height: 100, width: 100, depth: 200, anchorPosition: .center)
            let point = AGSPoint(x: relativeSurfacePoint.x, y: relativeSurfacePoint.y, spatialReference: .wgs84())
            self.graphicsOverlay.graphics.add(AGSGraphic(geometry: point, symbol: marker))
            
            // Get the surface elevation at the surface point.
            self.sceneView.scene?.baseSurface!.elevation(for: relativeSurfacePoint) { (results: Double, error: Error?) in
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    self.showPopover(elevation: results, popoverPoint: screenPoint)
                }
            }
        }
    }

    private func showPopover(elevation: Double, popoverPoint: CGPoint) {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "ElevationViewController") as? ElevationViewController else {
                return
        }
        // setup the controller to display as a popover
//        controller.elevationLabel?.text?.append(String(elevation.rounded()) + String("m"))
        controller.modalPresentationStyle = .popover
        controller.loadViewIfNeeded()
//        Measurement(value: elevation.rounded(), unit: UnitLength.meters)
        controller.elevationLabel?.text? = "Elevation at tapped point: " + (String(elevation.rounded()) + String("m"))
        controller.presentationController?.delegate = self
        controller.preferredContentSize = CGSize(width: 280, height: 40)
        controller.popoverPresentationController?.passthroughViews = [sceneView as Any, navigationController?.viewControllers as Any] as? [UIView]
        controller.popoverPresentationController?.sourceRect = CGRect(origin: popoverPoint, size: .zero)
        controller.popoverPresentationController?.sourceView = sceneView
        present(controller, animated: true)
    }
}

extension GetElevationPointViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
