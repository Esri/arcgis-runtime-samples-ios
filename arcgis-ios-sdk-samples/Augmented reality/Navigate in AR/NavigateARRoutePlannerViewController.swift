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
            mapView.map = AGSMap(basemap: .imageryWithLabelsVector())
            mapView.graphicsOverlays.addObjects(from: [routeGraphicsOverlay, stopGraphicsOverlay])
            mapView.locationDisplay.dataSource = locationDataSource
            mapView.locationDisplay.autoPanMode = .recenter
        }
    }
    
    // MARK: Instance properties
    
    /// The route task to solve the route between start and destination, with authentication required.
    let routeTask = AGSRouteTask(url: URL(string: "https://route.arcgis.com/arcgis/rest/services/World/Route/NAServer/Route_World")!)
    ///
    var routeParameters: AGSRouteParameters!
    ///
    let locationDataSource = AGSCLLocationDataSource()
    ///
    let stopGraphicsOverlay = AGSGraphicsOverlay()
    
    ///
    let oAuthConfiguration: AGSOAuthConfiguration = {
        let portalURL = URL(string: "https://www.arcgis.com")!
        let clientID = "lgAdHkYZYlwwfAhC"
        let redirectURLString = "my-ags-app://auth"
        return AGSOAuthConfiguration(portalURL: portalURL, clientID: clientID, redirectURL: redirectURLString)
    }()
    
    ///
    let routeGraphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        overlay.renderer = AGSSimpleRenderer(
            symbol: AGSSimpleLineSymbol(style: .solid, color: .yellow, width: 5)
        )
        return overlay
    }()
    
    ///
    var startPoint: AGSPoint? {
        didSet {
            resetButtonItem.isEnabled = true
            let stopSymbol = AGSPictureMarkerSymbol(image: UIImage(named: "StopA")!)
            let startStopGraphic = AGSGraphic(geometry: self.startPoint, symbol: stopSymbol)
            stopGraphicsOverlay.graphics.add(startStopGraphic)
        }
    }
    
    ///
    var endPoint: AGSPoint? {
        didSet {
            let stopSymbol = AGSPictureMarkerSymbol(image: UIImage(named: "StopB")!)
            let endStopGraphic = AGSGraphic(geometry: self.endPoint, symbol: stopSymbol)
            stopGraphicsOverlay.graphics.add(endStopGraphic)
        }
    }
    
    ///
    var routeResult: AGSRouteResult? {
        willSet(newValue) {
            if newValue != nil {
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
    
    /// A wrapper function for operations after the route is solved by an AGSRouteTask.
    ///
    /// - Parameters:
    ///   - routeResult: The result from `AGSRouteTask.solveRoute(with:completion:)`.
    ///   - error: The error from `AGSRouteTask.solveRoute(with:completion:)`.
    func didSolveRoute(with routeResult: AGSRouteResult?, error: Error?) {
        if let error = error {
            self.presentAlert(error: error)
            self.setStatus(message: "Solve route failed.")
        } else if let result = routeResult, let firstRoute = result.routes.first {
            self.routeResult = result
            let routeGraphic = AGSGraphic(geometry: firstRoute.routeGeometry, symbol: nil)
            self.routeGraphicsOverlay.graphics.add(routeGraphic)
            self.setStatus(message: "Tap camera to start navigation.")
        }
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    // MARK: - Actions
    
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
            "NavigateARNavigatorViewController"
        ]
        // Avoid overlapping status label and map content.
        mapView.contentInset.top = 2 * statusLabel.font.lineHeight
        
        // Configure the authentication manager to show the OAuth dialog.
        AGSAuthenticationManager.shared().delegate = self
        AGSAuthenticationManager.shared().oAuthConfigurations.add(oAuthConfiguration)
        
        routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
                self.setStatus(message: "Loading route parameters failed.")
                return
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
        
        mapView.locationDisplay.start()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNavigator" {
            if let navigatorVC = segue.destination as? NavigateARNavigatorViewController {
                navigatorVC.routeResult = routeResult!
                navigatorVC.routeTask = routeTask
                navigatorVC.routeParameters = routeParameters
            }
        }
    }
    
    deinit {
        AGSAuthenticationManager.shared().oAuthConfigurations.removeAllObjects()
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
            routeTask.solveRoute(with: routeParameters) { [weak self] in
                self?.didSolveRoute(with: $0, error: $1)
            }
        }
    }
}

// MARK: - Show OAuth dialog for route service

extension NavigateARRoutePlannerViewController: AGSAuthenticationManagerDelegate {
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, wantsToShow viewController: UIViewController) {
        viewController.modalPresentationStyle = .formSheet
        present(viewController, animated: true)
    }
    
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, wantsToDismiss viewController: UIViewController) {
        dismiss(animated: true)
    }
}
