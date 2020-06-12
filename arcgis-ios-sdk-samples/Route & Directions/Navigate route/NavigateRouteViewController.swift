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
import AVFoundation
import ArcGIS

// MARK: - Navigate route View Controller

class NavigateRouteViewController: UIViewController {
    // MARK: Instance properties
    
    /// The route result solved by the route task.
    var routeResult: AGSRouteResult!
    /// The original view point that can be reset to later on.
    var defaultViewPoint: AGSViewpoint?
    /// The graphic (with a dashed line symbol) to represent the route ahead.
    var routeAheadGraphic: AGSGraphic!
    /// The graphic to represent the route that's been traveled (initially empty).
    var routeTraveledGraphic: AGSGraphic!
    /// A list to keep track of directions solved by the route task.
    var directionsList: [AGSDirectionManeuver] = []
    /// The route tracker for navigation. Use delegate methods to update tracking status.
    var routeTracker: AGSRouteTracker!
    /// The route task to solve the route between stops, using the online routing service.
    var routeTask: AGSRouteTask!
    /// The initial location for the solved route.
    var initialLocation: AGSLocation!
    /// A formatter to format a time value into human readable string.
    lazy var timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter
    }()
    /// An AVSpeechSynthesizer for text to speech.
    lazy var speechSynthesizer = AVSpeechSynthesizer()
    
    // MARK: Storyboard views
    
    /// The button to initiate navigation.
    @IBOutlet weak var navigateButtonItem: UIBarButtonItem!
    /// The button to reset navigation.
    @IBOutlet weak var resetButtonItem: UIBarButtonItem!
    /// The button to recenter the map to navigation pan mode.
    @IBOutlet weak var recenterButtonItem: UIBarButtonItem!
    /// The label to display navigation status.
    @IBOutlet weak var statusLabel: UILabel!
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: .navigationVector())
            mapView.graphicsOverlays.add(makeRouteOverlay())
        }
    }
    
    // MARK: Instance methods
    
    /// A wrapper function for operations after the route is solved by an `AGSRouteTask`.
    ///
    /// - Parameter routeResult: The result from `AGSRouteTask.solveRoute(with:completion:)`.
    func didSolveRoute(with routeResult: Result<AGSRouteResult, Error>) {
        switch routeResult {
        case .success(let routeResult):
            self.routeResult = routeResult
            let firstRoute = routeResult.routes.first!
            mapView.locationDisplay.dataSource = makeDataSource(from: firstRoute)
            routeTracker = makeRouteTracker(result: routeResult)
            updateRouteGraphics(remaining: firstRoute.routeGeometry)
            updateViewpoint(from: routeResult)
            // Enable bar button item.
            navigateButtonItem.isEnabled = true
        case .failure(let error):
            presentAlert(error: error)
            setStatus(message: "Failed to solve route.")
        }
    }
    
    /// Create the stops for the navigation.
    ///
    /// - Returns: An array of `AGSStop` objects.
    func makeStops() -> [AGSStop] {
        let stop1 = AGSStop(point: AGSPoint(x: -117.160386727, y: 32.706608, spatialReference: .wgs84()))
        stop1.name = "San Diego Convention Center"
        let stop2 = AGSStop(point: AGSPoint(x: -117.173034, y: 32.712329, spatialReference: .wgs84()))
        stop2.name = "USS San Diego Memorial"
        let stop3 = AGSStop(point: AGSPoint(x: -117.147230, y: 32.730467, spatialReference: .wgs84()))
        stop3.name = "RH Fleet Aerospace Museum"
        return [stop1, stop2, stop3]
    }
    
    /// Make the simulated data source for this demo.
    ///
    /// - Parameter result: Solved `AGSRouteResult` from the route task.
    /// - Returns: An `AGSSimulatedLocationDataSource` object.
    func makeDataSource(from route: AGSRoute) -> AGSSimulatedLocationDataSource {
        directionsList = route.directionManeuvers
        let densifiedRoute = AGSGeometryEngine.geodeticDensifyGeometry(route.routeGeometry!, maxSegmentLength: 50.0, lengthUnit: .meters(), curveType: .geodesic) as! AGSPolyline
        // The mock data source to demo the navigation. Use delegate methods to update locations for the tracker.
        let mockDataSource = AGSSimulatedLocationDataSource()
        mockDataSource.setLocationsWith(densifiedRoute)
        mockDataSource.locationChangeHandlerDelegate = self
        initialLocation = mockDataSource.locations?.first
        return mockDataSource
    }
    
    /// Make a route tracker to provide navigation information.
    ///
    /// - Parameter result: Solved `AGSRouteResult` from the route task.
    /// - Returns: An `AGSRouteTracker` object.
    func makeRouteTracker(result: AGSRouteResult) -> AGSRouteTracker {
        let tracker = AGSRouteTracker(routeResult: result, routeIndex: 0)!
        tracker.delegate = self
        return tracker
    }
    
    /// Make a graphic overlay and add graphics to it.
    ///
    /// - Returns: An `AGSGraphicsOverlay` object.
    func makeRouteOverlay() -> AGSGraphicsOverlay {
        // The graphics overlay for the polygon and points.
        let graphicsOverlay = AGSGraphicsOverlay()
        // Add stops graphics to the graphic overlay.
        let stopSymbol = AGSSimpleMarkerSymbol(style: .diamond, color: .orange, size: 20)
        graphicsOverlay.graphics.addObjects(from: makeStops().map { AGSGraphic(geometry: $0.geometry, symbol: stopSymbol) })
        routeAheadGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .dash, color: .systemPurple, width: 5))
        routeTraveledGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .solid, color: .systemBlue, width: 3))
        graphicsOverlay.graphics.addObjects(from: [
            routeAheadGraphic!,
            routeTraveledGraphic!
        ])
        return graphicsOverlay
    }
    
    /// Update the viewpoint so that it reflects the original viewpoint when the example is loaded.
    ///
    /// - Parameter result: Solved `AGSRouteResult` from the route task.
    func updateViewpoint(from result: AGSRouteResult) {
        // Show the resulting route on the map and save a reference to the route.
        if let viewPoint = defaultViewPoint {
            // Reset to initial view point with animation.
            mapView.setViewpoint(viewPoint, completion: nil)
        } else if let geometry = result.routes.first?.routeGeometry {
            mapView.setViewpointGeometry(geometry) { [weak self] _ in
                // Get the initial zoomed view point.
                self?.defaultViewPoint = self?.mapView.currentViewpoint(with: .centerAndScale)
            }
        }
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    // MARK: Actions
    
    /// Called in response to the "Navigate" button being tapped.
    @IBAction func startNavigation() {
        navigateButtonItem.isEnabled = false
        resetButtonItem.isEnabled = true
        mapView.locationDisplay.autoPanMode = .navigation
        // If the user navigates the map view away from the location display, activate the recenter button.
        mapView.locationDisplay.autoPanModeChangedHandler = { [weak self] _ in self?.recenterButtonItem.isEnabled = true }
        // Start the location data source and location display.
        mapView.locationDisplay.start()
    }
    
    /// Called in response to the "Reset" button being tapped.
    @IBAction func reset() {
        // Stop the speech, if there is any.
        speechSynthesizer.stopSpeaking(at: .immediate)
        // Reset to the starting location for location display.
        mapView.locationDisplay.dataSource.didUpdate(initialLocation)
        // Stop the location display as well as datasource generation, if reset before the end is reached.
        mapView.locationDisplay.stop()
        mapView.locationDisplay.autoPanMode = .off
        directionsList.removeAll()
        setStatus(message: "Directions are shown here.")
        // Reset the navigation.
        mapView.locationDisplay.dataSource = makeDataSource(from: routeResult.routes.first!)
        routeTracker = makeRouteTracker(result: routeResult)
        updateRouteGraphics(remaining: (routeResult.routes.first?.routeGeometry)!)
        updateViewpoint(from: routeResult)
        // Reset buttons state.
        recenterButtonItem.isEnabled = false
        resetButtonItem.isEnabled = false
        navigateButtonItem.isEnabled = true
    }
    
    /// Called in response to the "Recenter" button being tapped.
    @IBAction func recenter() {
        mapView.locationDisplay.autoPanMode = .navigation
        recenterButtonItem.isEnabled = false
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Avoid the overlap between the label and the map content.
        mapView.contentInset.top = CGFloat(statusLabel.numberOfLines) * statusLabel.font.lineHeight
        // Solve the route as map loads.
        routeTask = AGSRouteTask(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/Route")!)
        routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
                self.setStatus(message: "Failed to get route parameters.")
            } else if let params = params {
                // Explicitly set values for parameters.
                params.returnDirections = true
                params.returnStops = true
                params.returnRoutes = true
                params.outputSpatialReference = .wgs84()
                params.setStops(self.makeStops())
                self.routeTask.solveRoute(with: params) { [weak self] (result, error) in
                    if let error = error {
                        self?.didSolveRoute(with: .failure(error))
                    } else if let result = result {
                        self?.didSolveRoute(with: .success(result))
                    }
                }
            }
        }
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["NavigateRouteViewController"]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only reset when the route is successfully solved.
        if routeResult != nil {
            reset()
        }
    }
}

// MARK: - AGSRouteTrackerDelegate

extension NavigateRouteViewController: AGSRouteTrackerDelegate {
    func routeTracker(_ routeTracker: AGSRouteTracker, didGenerateNewVoiceGuidance voiceGuidance: AGSVoiceGuidance) {
        setSpeakDirection(with: voiceGuidance.text)
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, didUpdate trackingStatus: AGSTrackingStatus) {
        updateTrackingStatusDisplay(with: trackingStatus)
    }
    
    func setSpeakDirection(with text: String) {
        speechSynthesizer.stopSpeaking(at: .word)
        speechSynthesizer.speak(AVSpeechUtterance(string: text))
    }
    
    func updateTrackingStatusDisplay(with status: AGSTrackingStatus) {
        var statusText: String
        switch status.destinationStatus {
        case .notReached, .approaching:
            let distanceRemaining = status.routeProgress.remainingDistance.displayText + " " + status.routeProgress.remainingDistance.displayTextUnits.pluralDisplayName
            let timeRemaining = timeFormatter.string(from: TimeInterval(status.routeProgress.remainingTime * 60))!
            statusText = """
            Distance remaining: \(distanceRemaining)
            Time remaining: \(timeRemaining)
            """
            if status.currentManeuverIndex + 1 < directionsList.count {
                let nextDirection = directionsList[status.currentManeuverIndex + 1].directionText
                statusText.append("\nNext direction: \(nextDirection)")
            }
        case .reached:
            if status.remainingDestinationCount > 1 {
                statusText = "Intermediate stop reached, continue to next stop."
                routeTracker?.switchToNextDestination()
            } else {
                statusText = "Final destination reached."
                mapView.locationDisplay.stop()
            }
        default:
            return
        }
        updateRouteGraphics(remaining: status.routeProgress.remainingGeometry, traversed: status.routeProgress.traversedGeometry)
        setStatus(message: statusText)
    }
    
    func updateRouteGraphics(remaining: AGSGeometry?, traversed: AGSGeometry? = nil) {
        routeAheadGraphic.geometry = remaining
        routeTraveledGraphic.geometry = traversed
    }
}

// MARK: - AGSLocationChangeHandlerDelegate

extension NavigateRouteViewController: AGSLocationChangeHandlerDelegate {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        // Update the tracker location with the new location from the simulated data source.
        routeTracker?.trackLocation(location)
    }
}
