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

/// A view controller that manages the interface of the Get Elevation at a Point
/// sample.
class GetElevationPointViewController: UIViewController {
    /// The scene view managed by the view controller.
    @IBOutlet var sceneView: AGSSceneView! {
        didSet {
            // Initialize a scene.
            sceneView.scene = makeScene()
            
            sceneView.touchDelegate = self
            
            // Set scene's viewpoint.
            let camera = AGSCamera(latitude: 28.42, longitude: 83.9, altitude: 10000.0, heading: 10.0, pitch: 80.0, roll: 0.0)
            sceneView.setViewpointCamera(camera)
            sceneView.graphicsOverlays.add(graphicsOverlay)
        }
    }
    
    /// The graphics overlay used to show a graphic at the tapped point.
    private let graphicsOverlay: AGSGraphicsOverlay = {
        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.renderingMode = .dynamic
        graphicsOverlay.sceneProperties?.surfacePlacement = .relative
        return graphicsOverlay
    }()
    
    /// Creates a scene.
    ///
    /// - Returns: A new `AGSScene` object with a base surface configured with
    /// an elevation source.
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
    
    /// Dismisses the elevation popover and removes the associated graphic.
    func dismissElevationPopover() {
        guard presentedViewController != nil else { return }
        dismiss(animated: false)
        sceneView.viewpointChangedHandler = nil
        graphicsOverlay.graphics.removeAllObjects()
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GetElevationPointViewController", "ElevationViewController"]
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        dismissElevationPopover()
    }
}

// MARK: - AGSGeoViewTouchDelegate
extension GetElevationPointViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let relativeSurfacePoint = sceneView?.screen(toBaseSurface: screenPoint) {
            dismiss(animated: false)
            
            // Get the tapped point
            let point = AGSPoint(x: relativeSurfacePoint.x, y: relativeSurfacePoint.y, spatialReference: .wgs84())
            if let graphic = graphicsOverlay.graphics.firstObject as? AGSGraphic {
                // Move the symbol to the tapped point.
                graphic.geometry = point
            } else {
                // Create the symbol at the tapped point.
                let marker = AGSSimpleMarkerSceneSymbol(style: .sphere, color: .red, height: 100, width: 100, depth: 100, anchorPosition: .center)
                let graphic = AGSGraphic(geometry: point, symbol: marker)
                graphicsOverlay.graphics.add(graphic)
            }
            
            // Get the surface elevation at the surface point.
            self.sceneView.scene?.baseSurface!.elevation(for: relativeSurfacePoint) { (results: Double, error: Error?) in
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    self.showPopover(elevation: results, popoverPoint: screenPoint)
                }
            }
        }
        // Dismiss the elevation popover and hide the graphic when the user
        // interacts with the scene.
        sceneView.viewpointChangedHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.dismissElevationPopover()
            }
        }
    }

    private func showPopover(elevation: Double, popoverPoint: CGPoint) {
        guard let elevationViewController = storyboard?.instantiateViewController(withIdentifier: "ElevationViewController") as? ElevationViewController else {
                return
        }
        // Setup the controller to display as a popover.
        elevationViewController.modalPresentationStyle = .popover
        elevationViewController.elevation = Measurement(value: elevation, unit: UnitLength.meters)
        if let popoverPresentationController = elevationViewController.popoverPresentationController {
            popoverPresentationController.delegate = self
            popoverPresentationController.passthroughViews = [sceneView]
            popoverPresentationController.sourceRect = CGRect(origin: popoverPoint, size: .zero)
            popoverPresentationController.sourceView = sceneView
        }
        present(elevationViewController, animated: false)
    }
}

extension GetElevationPointViewController: UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        // Clear selection when popover is dismissed.
        graphicsOverlay.graphics.removeAllObjects()
    }
}
