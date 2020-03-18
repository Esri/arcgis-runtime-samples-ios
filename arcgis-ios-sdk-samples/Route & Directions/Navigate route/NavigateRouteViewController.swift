// Copyright 2020 Esri
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

class NavigateRouteViewController: UIViewController {
    let routeStops: [AGSStop] = {[
            // San Diego Convention Center.
            AGSStop(point: AGSPoint(x: -117.160386727, y: 32.706608, spatialReference: AGSSpatialReference.wgs84())),
            // USS San Diego Memorial.
            AGSStop(point: AGSPoint(x: -117.173034, y: 32.712327, spatialReference: AGSSpatialReference.wgs84())),
            // RH Fleet Aerospace Museum.
            AGSStop(point: AGSPoint(x: -117.147230, y: 32.730467, spatialReference: AGSSpatialReference.wgs84()))
        ]}()
    
    var routeTask: AGSRouteTask!
    var routeResult: AGSRouteResult?
    
    /// The graphics overlay for the polygon and points..
    let graphicsOverlay = AGSGraphicsOverlay()
    
    /// The bar button item that initiates the create convex hull operation.
    @IBOutlet weak var navigateButtonItem: UIBarButtonItem!
    
    /// The bar button item that removes the convex hull as well as the MapPoints.
    @IBOutlet weak var resetButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var recenterButtonItem: UIBarButtonItem!
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .navigationVector())
        self.getDefaultParameters { (params: AGSRouteParameters) in
            self.solveRoute(params)
        }
        return map
    }
    
    // Gets the default parameters for the route task and invoke solve route.
    func getDefaultParameters(completion: @escaping (AGSRouteParameters) -> Void) {
        let featureServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route")!
        routeTask = AGSRouteTask(url: featureServiceURL)
        routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Unwrap the AGSRouteParameters if there is no error.
                guard let params = params else { return }
                // Explicitly set values for parameters.
                params.returnDirections = true
                params.returnStops = true
                params.returnRoutes = true
                params.outputSpatialReference = .wgs84()
                // Add stops
                params.setStops(self.routeStops)
                completion(params)
            }
        }
    }
    
    func solveRoute(_ params: AGSRouteParameters) {
        routeTask.solveRoute(with: params) { (routeResult: AGSRouteResult?, error: Error?) in
            if let error = error {
                self.presentAlert(error: error)
            } else if let routeResult = routeResult, let route = routeResult.routes.first {
                self.routeResult = routeResult
                // Show the resulting route on the map and save a reference to the route.
                let routeAheadGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: AGSSimpleLineSymbol(style: .dash, color: .systemPurple, width: 5), attributes: nil)
                let routeTraveledGraphic = AGSGraphic(geometry: route.routeGeometry, symbol: AGSSimpleLineSymbol(style: .solid, color: .systemBlue, width: 3), attributes: nil)
                self.graphicsOverlay.graphics.addObjects(from: [
                    routeAheadGraphic,
                    routeTraveledGraphic
                ])
                #warning("probably buggy dispatch sequence")
                if let routeGeometry = route.routeGeometry {
                    self.mapView.setViewpointGeometry(routeGeometry, completion: nil)
                }
                // Enable bar button item.
                self.navigateButtonItem.isEnabled = true
            }
        }
    }
    
    /// Called in response to the Navigate button being tapped.
    @IBAction func startNavigation() {
        navigateButtonItem.isEnabled = false
        if let routeResult = routeResult, let route = routeResult.routes.first {
            let directionsList = route.directionManeuvers
            let tracker = AGSRouteTracker(routeResult: routeResult, routeIndex: 0)
            tracker?.delegate = self
        }
        
        // If the user navigates the map view away from the location display, activate the recenter button.
        mapView.locationDisplay.autoPanModeChangedHandler = { _ in self.recenterButtonItem.isEnabled = true }
    }
    
    /// Called in response to the Reset button being tapped.
    @IBAction func reset() {
        // Clear the existing points and graphics.
        
    }
    
    /// Called in response to the Recenter button being tapped.
    @IBAction func recenter() {
        recenterButtonItem.isEnabled = false
        mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanMode.navigation
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["NavigateRouteViewController"]
    }
}


extension NavigateRouteViewController: AGSRouteTrackerDelegate {
    func routeTracker(_ routeTracker: AGSRouteTracker, didGenerateNewVoiceGuidance voiceGuidance: AGSVoiceGuidance) {
        <#code#>
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, didUpdate trackingStatus: AGSTrackingStatus) {
        <#code#>
    }
    
    func speakDirections() {
        
    }
    
    func updateTrackingStatus() {
        
    }
}

// will use AVSpeechSynthesizer to text to speech
