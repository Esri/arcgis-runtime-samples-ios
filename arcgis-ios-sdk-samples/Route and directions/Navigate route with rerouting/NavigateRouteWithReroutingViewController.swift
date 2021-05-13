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

class NavigateRouteWithReroutingViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The label to display navigation status.
    @IBOutlet var statusLabel: UILabel!
    /// The button to start navigation.
    @IBOutlet var navigateBarButtonItem: UIBarButtonItem!
    /// The button to reset navigation.
    @IBOutlet var resetBarButtonItem: UIBarButtonItem!
    /// The button to recenter the map to navigation pan mode.
    @IBOutlet var recenterBarButtonItem: UIBarButtonItem!
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISNavigation)
            mapView.graphicsOverlays.add(makeRouteOverlay())
        }
    }
    
    // MARK: Instance properties
    
    /// The route task to solve the route between stops, using the online routing service.
    let routeTask = AGSRouteTask(databaseName: "sandiego", networkName: "Streets_ND")
    /// The route result solved by the route task.
    var routeResult: AGSRouteResult!
    /// The route tracker for navigation. Use delegate methods to update tracking status.
    var routeTracker: AGSRouteTracker!
    /// The parameters of the route tracker.
    var routeParameters: AGSRouteParameters!
    /// A list to keep track of directions solved by the route task.
    var directionManeuvers: [AGSDirectionManeuver] = []
    /// The graphic (with a dashed line symbol) to represent the route ahead.
    let routeAheadGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .dash, color: .systemPurple, width: 5))
    /// The graphic to represent the route that's been traveled (initially empty).
    let routeTraveledGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .solid, color: .systemBlue, width: 3))
    /// The original view point that can be reset later on.
    var defaultViewPoint: AGSViewpoint?
    /// The starting location, the San Diego Convention Center.
    let startLocation = AGSPoint(x: -117.160386727, y: 32.706608, spatialReference: .wgs84())
    /// The destination location, the Fleet Science Center.
    let destinationLocation = AGSPoint(x: -117.146679, y: 32.730351, spatialReference: .wgs84())
    /// The location data source provided by a local GPX file.
    var gpxDataSource: AGSGPXLocationDataSource?
    
    /// A formatter to format a time value into human readable string.
    let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter
    }()
    /// An AVSpeechSynthesizer for text to speech.
    let speechSynthesizer = AVSpeechSynthesizer()
    
    // MARK: Actions
    
    /// Called in response to the "Navigate" button being tapped.
    @IBAction func startNavigation() {
        navigateBarButtonItem.isEnabled = false
        resetBarButtonItem.isEnabled = true
        // Start the location data source and location display.
        mapView.locationDisplay.start()
    }
    
    /// Called in response to the "Reset" button being tapped.
    @IBAction func reset() {
        // Stop the speech, if there is any.
        speechSynthesizer.stopSpeaking(at: .immediate)
        // Set the initial location.
        guard let initialLocation = gpxDataSource?.locations?.first else { return }
        // Reset to the starting location for location display.
        mapView.locationDisplay.dataSource.didUpdate(initialLocation)
        // Stop the location display as well as datasource generation, if reset before the end is reached.
        mapView.locationDisplay.stop()
        mapView.locationDisplay.autoPanModeChangedHandler = nil
        mapView.locationDisplay.autoPanMode = .off
        directionManeuvers.removeAll()
        setStatus(message: "Directions are shown here.")
        
        // Reset the navigation.
        setNavigation(with: routeResult)
        // Reset buttons state.
        resetBarButtonItem.isEnabled = false
        navigateBarButtonItem.isEnabled = true
    }
    
    /// Called in response to the "Recenter" button being tapped.
    @IBAction func recenter() {
        mapView.locationDisplay.autoPanMode = .navigation
        recenterBarButtonItem.isEnabled = false
        mapView.locationDisplay.autoPanModeChangedHandler = { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.recenterBarButtonItem.isEnabled = true
                self.mapView.locationDisplay.autoPanModeChangedHandler = nil
            }
        }
    }
    
    // MARK: Instance methods
    
    /// A wrapper function for operations after the route is solved by an `AGSRouteTask`.
    ///
    /// - Parameter result: The result of the solve route operation.
    func didSolveRoute(with result: Result<AGSRouteResult, Error>) {
        switch result {
        case .success(let routeResult):
            self.routeResult = routeResult
            setNavigation(with: routeResult)
            navigateBarButtonItem.isEnabled = true
        case .failure(let error):
            presentAlert(error: error)
            setStatus(message: "Failed to solve route.")
            navigateBarButtonItem.isEnabled = false
        }
    }
    
    /// Make a graphics overlay with graphics.
    ///
    /// - Returns: A new `AGSGraphicsOverlay` object.
    func makeRouteOverlay() -> AGSGraphicsOverlay {
        // The graphics overlay for the polygon and points.
        let graphicsOverlay = AGSGraphicsOverlay()
        // Create a graphic for the start location.
        let startSymbol = AGSSimpleMarkerSymbol(style: .cross, color: .green, size: 25)
        let startGraphic = AGSGraphic(geometry: startLocation, symbol: startSymbol)
        // Create a graphic for the destination location.
        let destinationSymbol = AGSSimpleMarkerSymbol(style: .X, color: .red, size: 20)
        let destinationGraphic = AGSGraphic(geometry: destinationLocation, symbol: destinationSymbol)
        // Add graphics to the graphics overlay.
        graphicsOverlay.graphics.addObjects(from: [startGraphic, destinationGraphic, routeAheadGraphic, routeTraveledGraphic])
        return graphicsOverlay
    }
    
    /// Create the stops for the navigation.
    ///
    /// - Returns: An array of `AGSStop` objects.
    func makeStops() -> [AGSStop] {
        let stop1 = AGSStop(point: startLocation)
        stop1.name = "San Diego Convention Center"
        let stop2 = AGSStop(point: destinationLocation)
        stop2.name = "RH Fleet Aerospace Museum"
        return [stop1, stop2]
    }
    
    /// Make a route tracker to provide navigation information.
    ///
    /// - Parameter result: An `AGSRouteResult` object used to configure the route tracker.
    /// - Returns: An `AGSRouteTracker` object.
    func makeRouteTracker(result: AGSRouteResult) -> AGSRouteTracker {
        let tracker = AGSRouteTracker(routeResult: result, routeIndex: 0, skipCoincidentStops: true)!
        if routeTask.routeTaskInfo().supportsRerouting {
            let reroutingParameters = AGSReroutingParameters(routeTask: routeTask, routeParameters: routeParameters)!
            tracker.enableRerouting(with: reroutingParameters) { error in
                if let error = error {
                    self.presentAlert(error: error)
                }
            }
        }
        tracker.delegate = self
        tracker.voiceGuidanceUnitSystem = Locale.current.usesMetricSystem ? .metric : .imperial
        return tracker
    }
    
    /// Set route tracker, data source, and location display with a solved route result.
    ///
    /// - Parameter routeResult: An `AGSRouteResult` object.
    func setNavigation(with routeResult: AGSRouteResult) {
        // Set the route tracker
        routeTracker = makeRouteTracker(result: routeResult)
        
        // Set the mock location data source.
        let firstRoute = routeResult.routes.first!
        directionManeuvers = firstRoute.directionManeuvers
        // Create the data source from a local GPX file.
        let gpxDataSource = AGSGPXLocationDataSource(name: "navigate_a_route_detour")
        self.gpxDataSource = gpxDataSource
        // Create a route tracker location data source to snap the location display to the route.
        let routeTrackerLocationDataSource = AGSRouteTrackerLocationDataSource(routeTracker: routeTracker, locationDataSource: gpxDataSource)
        
        // Set location display.
        mapView.locationDisplay.dataSource = routeTrackerLocationDataSource
        recenter()
        
        // Update graphics and viewpoint.
        let firstRouteGeometry = firstRoute.routeGeometry!
        updateRouteGraphics(remaining: firstRouteGeometry)
        updateViewpoint(geometry: firstRouteGeometry)
    }
    
    /// Update the viewpoint so that it reflects the original viewpoint when the example is loaded.
    ///
    /// - Parameter result: An `AGSGeometry` object used to update the view point.
    func updateViewpoint(geometry: AGSGeometry) {
        // Show the resulting route on the map and save a reference to the route.
        if let viewPoint = defaultViewPoint {
            // Reset to initial view point with animation.
            mapView.setViewpoint(viewPoint, completion: nil)
        } else {
            mapView.setViewpointGeometry(geometry) { [weak self] _ in
                guard let self = self else { return }
                // Get the initial zoomed view point.
                self.defaultViewPoint = self.mapView.currentViewpoint(with: .centerAndScale)
            }
        }
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["NavigateRouteWithReroutingViewController"]
        // Avoid the overlap between the status label and the map content.
        mapView.contentInset.top = CGFloat(statusLabel.numberOfLines) * statusLabel.font.lineHeight
        
        // Solve the route as map loads.
        routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) in
            guard let self = self else { return }
            if let params = params {
                // Explicitly set values for parameters.
                params.returnDirections = true
                params.returnStops = true
                params.returnRoutes = true
                params.outputSpatialReference = .wgs84()
                params.setStops(self.makeStops())
                self.routeParameters = params
                self.routeTask.solveRoute(with: params) { [weak self] (result, error) in
                    if let result = result {
                        self?.didSolveRoute(with: .success(result))
                    } else if let error = error {
                        self?.didSolveRoute(with: .failure(error))
                    }
                }
            } else if let error = error {
                self.presentAlert(error: error)
                self.setStatus(message: "Failed to get route parameters.")
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Reset the sample.
        reset()
    }
}

// MARK: - AGSRouteTrackerDelegate

extension NavigateRouteWithReroutingViewController: AGSRouteTrackerDelegate {
    func routeTracker(_ routeTracker: AGSRouteTracker, didGenerateNewVoiceGuidance voiceGuidance: AGSVoiceGuidance) {
        setSpeakDirection(with: voiceGuidance.text)
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, didUpdate trackingStatus: AGSTrackingStatus) {
        updateTrackingStatusDisplay(routeTracker: routeTracker, status: trackingStatus)
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, rerouteDidCompleteWith trackingStatus: AGSTrackingStatus?, error: Error?) {
        if let error = error {
            presentAlert(error: error)
        } else if let status = trackingStatus {
            // Get the new directions.
            directionManeuvers = status.routeResult.routes.first!.directionManeuvers
        }
    }
    
    func setSpeakDirection(with text: String) {
        speechSynthesizer.stopSpeaking(at: .word)
        speechSynthesizer.speak(AVSpeechUtterance(string: text))
    }
    
    func updateTrackingStatusDisplay(routeTracker: AGSRouteTracker, status: AGSTrackingStatus) {
        var statusText: String
        switch status.destinationStatus {
        case .notReached, .approaching:
            let distanceRemaining = status.routeProgress.remainingDistance.displayText + " " + status.routeProgress.remainingDistance.displayTextUnits.abbreviation
            let timeRemaining = timeFormatter.string(from: TimeInterval(status.routeProgress.remainingTime * 60))!
            statusText = """
            Distance remaining: \(distanceRemaining)
            Time remaining: \(timeRemaining)
            """
            if status.currentManeuverIndex + 1 < directionManeuvers.endIndex {
                let nextDirection = directionManeuvers[status.currentManeuverIndex + 1].directionText
                statusText.append("\nNext direction: \(nextDirection)")
            }
        case .reached:
            mapView.locationDisplay.stop()
            statusText = "Destination reached."
            routeAheadGraphic.geometry = nil
        default:
            statusText = "Off route!"
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

extension NavigateRouteWithReroutingViewController: AGSLocationChangeHandlerDelegate {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        // Update the tracker location with the new location from the simulated data source.
        routeTracker?.trackLocation(location) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                // Display error message and stop further route tracking if it
                // fails due to formatting or licensing issue.
                self.setStatus(message: error.localizedDescription)
                locationDataSource.locationChangeHandlerDelegate = nil
            }
        }
    }
}
