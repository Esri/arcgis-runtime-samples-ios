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

// MARK: - Plan the route

class NavigateARRoutePlannerViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The button to initiate navigation in AR.
    @IBOutlet weak var navigateButtonItem: UIBarButtonItem!
    /// The button to reset route.
    @IBOutlet weak var resetButtonItem: UIBarButtonItem!
    /// The label to display route-planning status.
    @IBOutlet weak var statusLabel: UILabel!
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISImagery)
            mapView.graphicsOverlays.addObjects(from: [routeGraphicsOverlay, stopGraphicsOverlay])
            mapView.locationDisplay.dataSource = locationDataSource
            mapView.locationDisplay.autoPanMode = .recenter
        }
    }
    
    // MARK: Instance properties
    
    /// The route task that solves the route using the online routing service, using API key authentication.
    let routeTask = AGSRouteTask(url: URL(string: "https://route-api.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World")!)
    /// The parameters for route task to solve a route.
    var routeParameters: AGSRouteParameters!
    /// The data source to track device location and provide updates to location display.
    let locationDataSource = AGSCLLocationDataSource()
    /// A graphic overlay for start and destination graphics.
    let stopGraphicsOverlay = AGSGraphicsOverlay()
    
    /// A graphic overlay for route graphics.
    let routeGraphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        overlay.renderer = AGSSimpleRenderer(
            symbol: AGSSimpleLineSymbol(style: .solid, color: .yellow, width: 5)
        )
        return overlay
    }()
    
    /// An `AGSPoint` representing the start of navigation.
    var startPoint: AGSPoint? {
        didSet {
            resetButtonItem.isEnabled = true
            let stopSymbol = AGSPictureMarkerSymbol(image: UIImage(named: "StopA")!)
            let startStopGraphic = AGSGraphic(geometry: self.startPoint, symbol: stopSymbol)
            stopGraphicsOverlay.graphics.add(startStopGraphic)
        }
    }
    
    /// An `AGSPoint` representing the destination of navigation.
    var endPoint: AGSPoint? {
        didSet {
            let stopSymbol = AGSPictureMarkerSymbol(image: UIImage(named: "StopB")!)
            let endStopGraphic = AGSGraphic(geometry: self.endPoint, symbol: stopSymbol)
            stopGraphicsOverlay.graphics.add(endStopGraphic)
        }
    }
    
    /// The route result solved by the route task.
    var routeResult: AGSRouteResult? {
        willSet(newValue) {
            // Only enable when there is a valid route to navigate.
            if newValue?.routes.first != nil {
                navigateButtonItem.isEnabled = true
            }
        }
    }
    
    // MARK: Instance methods
    
    /// Create the start and destination stops for the navigation.
    ///
    /// - Returns: An array of `AGSStop` objects.
    func makeStops() -> [AGSStop] {
        let stop1 = AGSStop(point: self.startPoint!)
        stop1.name = "Start"
        let stop2 = AGSStop(point: self.endPoint!)
        stop2.name = "Destination"
        return [stop1, stop2]
    }
    
    /// A wrapper function for operations after the route is solved by an `AGSRouteTask`.
    ///
    /// - Parameter routeResult: The result from `AGSRouteTask.solveRoute(with:completion:)`.
    func didSolveRoute(with routeResult: Result<AGSRouteResult, Error>) {
        switch routeResult {
        case .success(let routeResult):
            self.routeResult = routeResult
            if let firstRoute = routeResult.routes.first {
                let routeGraphic = AGSGraphic(geometry: firstRoute.routeGeometry, symbol: nil)
                routeGraphicsOverlay.graphics.add(routeGraphic)
                setStatus(message: "Tap camera to start navigation.")
            }
        case .failure(let error):
            presentAlert(error: error)
            setStatus(message: "Failed to solve route.")
        }
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    // MARK: Actions
    
    @IBAction func reset() {
        routeGraphicsOverlay.graphics.removeAllObjects()
        stopGraphicsOverlay.graphics.removeAllObjects()
        routeParameters.clearStops()
        routeResult = nil
        startPoint = nil
        endPoint = nil
        resetButtonItem.isEnabled = false
        navigateButtonItem.isEnabled = false
        setStatus(message: "Tap to place a start point.")
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "NavigateARRoutePlannerViewController",
            "NavigateARNavigatorViewController",
            "NavigateARCalibrationViewController"
        ]
        // Avoid overlapping status label and map content.
        mapView.contentInset.top = 2 * statusLabel.font.lineHeight
        
        routeTask.load { [weak self] (error: Error?) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
                self.setStatus(message: "Failed to load route task. Check your connection or credentials.")
            } else {
                // Get route parameters if no error occurs.
                self.routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) in
                    guard let self = self else { return }
                    if let error = error {
                        self.presentAlert(error: error)
                        self.setStatus(message: "Failed to load route parameters.")
                    } else if let params = params {
                        // set the travel mode to the first one matching 'walking'
                        let walkMode = self.routeTask.routeTaskInfo().travelModes.first { $0.name.contains("Walking") }
                        params.travelMode = walkMode
                        params.returnStops = true
                        params.returnDirections = true
                        params.returnRoutes = true
                        self.routeParameters = params
                        self.mapView.touchDelegate = self
                        self.setStatus(message: "Tap to place a start point.")
                    }
                }
            }
        }
        
        mapView.locationDisplay.start()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNavigator" {
            if let navigatorViewController = segue.destination as? NavigateARNavigatorViewController {
                navigatorViewController.routeResult = routeResult!
                navigatorViewController.routeTask = routeTask
                navigatorViewController.routeParameters = routeParameters
            }
        }
    }
}

// MARK: - Set route start and end on touch

extension NavigateARRoutePlannerViewController: AGSGeoViewTouchDelegate {
    public func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if startPoint == nil {
            startPoint = mapPoint
            setStatus(message: "Tap to place destination.")
        } else if endPoint == nil {
            endPoint = mapPoint
            routeParameters.setStops(makeStops())
            routeTask.solveRoute(with: routeParameters) { [weak self] (result, error) in
                if let error = error {
                    self?.didSolveRoute(with: .failure(error))
                } else if let result = result {
                    self?.didSolveRoute(with: .success(result))
                }
            }
        }
    }
}
