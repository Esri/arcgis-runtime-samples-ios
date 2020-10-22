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
            mapView.map = AGSMap(basemap: .navigationVector())
            mapView.graphicsOverlays.add(makeRouteOverlay())
        }
    }
    
    // MARK: Instance properties
    var route: AGSRoute?
    /// The route task to solve the route between stops, using the online routing service.
    let routeTask = AGSRouteTask(databaseName: "sandiego", networkName: "Streets_ND")
    /// The route result solved by the route task.
    var routeResult: AGSRouteResult!
    /// The route tracker for navigation. Use delegate methods to update tracking status.
    var routeTracker: AGSRouteTracker!
    /// A list to keep track of directions solved by the route task.
    var directionsList: [AGSDirectionManeuver] = []
    /// The graphic (with a dashed line symbol) to represent the route ahead.
    let routeAheadGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .dash, color: .systemPurple, width: 5))
    /// The graphic to represent the route that's been traveled (initially empty).
    let routeTraveledGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .solid, color: .systemBlue, width: 3))
    /// The original view point that can be reset later on.
    var defaultViewPoint: AGSViewpoint?
    /// The initial location for the solved route.
    var initialLocation: AGSLocation!
    let startLocation = AGSPoint(x: -117.160386727, y: 32.706608, spatialReference: .wgs84())
    let destinationLocation = AGSPoint(x: -117.147230, y: 32.730467, spatialReference: .wgs84())
    var gpxPoints = [AGSPoint]()
    var routeParameters: AGSRouteParameters?
    
    /// A formatter to format a time value into human readable string.
    let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        return formatter
    }()
    /// An AVSpeechSynthesizer for text to speech.
    let speechSynthesizer = AVSpeechSynthesizer()
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
        // Reset to the starting location for location display.
        mapView.locationDisplay.dataSource.didUpdate(initialLocation)
        // Stop the location display as well as datasource generation, if reset before the end is reached.
        mapView.locationDisplay.stop()
        mapView.locationDisplay.autoPanModeChangedHandler = nil
        mapView.locationDisplay.autoPanMode = .off
        directionsList.removeAll()
//        setStatus(message: "Directions are shown here.")
        
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
            DispatchQueue.main.async { [weak self] in
                self?.recenterBarButtonItem.isEnabled = true
            }
            self?.mapView.locationDisplay.autoPanModeChangedHandler = nil
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
            setNavigation(with: routeResult)
            navigateBarButtonItem.isEnabled = true
        case .failure(let error):
            presentAlert(error: error)
//            setStatus(message: "Failed to solve route.")
            navigateBarButtonItem.isEnabled = false
        }
    }
    
    /// Make the simulated data source for this demo.
    ///
    /// - Parameter route: An `AGSRoute` object whose geometry is used to configure the data source.
    /// - Returns: An `AGSSimulatedLocationDataSource` object.
    func makeDetourDataSource(polyline: AGSPolyline) -> AGSSimulatedLocationDataSource {
        let densifiedRoute = AGSGeometryEngine.geodeticDensifyGeometry(polyline, maxSegmentLength: 50.0, lengthUnit: .meters(), curveType: .geodesic) as! AGSPolyline
        // The mock data source to demo the navigation. Use delegate methods to update locations for the tracker.
        let mockDataSource = AGSSimulatedLocationDataSource()
        mockDataSource.setLocationsWith(densifiedRoute)
        mockDataSource.locationChangeHandlerDelegate = self
        return mockDataSource
    }
    
    func makePolylineFromGPX() -> AGSPolyline {
        let gpxURL = Bundle.main.url(forResource: "navigate_a_route_detour", withExtension: "gpx")!
        let gpxDocument = XMLParser(contentsOf: gpxURL)
        gpxDocument?.delegate = self
        let didParseGPX = gpxDocument?.parse()
        if !didParseGPX! {
            print("Error parsing GPX document")
        }
        return AGSPolyline(points: gpxPoints)
    }
    
    /// Set route tracker, data source and location display with a solved route result.
    ///
    /// - Parameter routeResult: An `AGSRouteResult` object.
    func setNavigation(with routeResult: AGSRouteResult) {
        // Set the route tracker
        routeTracker = makeRouteTracker(result: routeResult)
        
        // Set the mock location data source.
        let firstRoute = routeResult.routes.first!
        directionsList = firstRoute.directionManeuvers
        
        let mockDataSource = makeDetourDataSource(polyline: makePolylineFromGPX())
        initialLocation = mockDataSource.locations?.first
        // Create a route tracker location data source to snap the location display to the route.
        let routeTrackerLocationDataSource = AGSRouteTrackerLocationDataSource(routeTracker: routeTracker, locationDataSource: mockDataSource)
        
        // Set location display.
        mapView.locationDisplay.dataSource = routeTrackerLocationDataSource
        recenter()
        
        // Update graphics and viewpoint.
        let firstRouteGeometry = firstRoute.routeGeometry!
        updateRouteGraphics(remaining: firstRouteGeometry)
        updateViewpoint(geometry: firstRouteGeometry)
        
        if routeTask.routeTaskInfo().supportsRerouting {
            routeTracker.enableRerouting(with: routeTask, routeParameters: routeParameters!, strategy: .toNextWaypoint, visitFirstStopOnStart: false) {_ in
                
            }
        }
    }
    /// Make a route tracker to provide navigation information.
    ///
    /// - Parameter result: An `AGSRouteResult` object used to configure the route tracker.
    /// - Returns: An `AGSRouteTracker` object.
    func makeRouteTracker(result: AGSRouteResult) -> AGSRouteTracker {
        let tracker = AGSRouteTracker(routeResult: result, routeIndex: 0, skipCoincidentStops: true)!
//        tracker.delegate?.routeTracker?(tracker, didGenerateNewVoiceGuidance: <#T##AGSVoiceGuidance#>)
        tracker.delegate = self
        tracker.voiceGuidanceUnitSystem = Locale.current.usesMetricSystem ? .metric : .imperial
        return tracker
    }
//    func rerouteStarted() {
//        // Remove the event listeners for tracking status changes while the route tracker recalculates
//        routeTracker.delegate?.routeTracker?(routeTracker, didGenerateNewVoiceGuidance: <#T##AGSVoiceGuidance#>)
//
//    }
    /// Make a graphics overlay with graphics.
    ///
    /// - Returns: An `AGSGraphicsOverlay` object.
    func makeRouteOverlay() -> AGSGraphicsOverlay {
        // The graphics overlay for the polygon and points.
        let graphicsOverlay = AGSGraphicsOverlay()
        let startSymbol = AGSSimpleMarkerSymbol(style: .cross, color: .green, size: 25)
        let startGraphic = AGSGraphic(geometry: startLocation, symbol: startSymbol, attributes: nil)
        let destinationSymbol = AGSSimpleMarkerSymbol(style: .X, color: .red, size: 20)
        let destinationGraphic = AGSGraphic(geometry: destinationLocation, symbol: destinationSymbol, attributes: nil)
        routeAheadGraphic.geometry = route?.routeGeometry
        // Add graphics to the graphics overlay.
        graphicsOverlay.graphics.addObjects(from: [startGraphic, destinationGraphic, routeAheadGraphic, routeTraveledGraphic])
        return graphicsOverlay
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
                // Get the initial zoomed view point.
                self?.defaultViewPoint = self?.mapView.currentViewpoint(with: .centerAndScale)
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
//        mapView.contentInset.top = CGFloat(statusLabel.numberOfLines) * statusLabel.font.lineHeight
        
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
                        self?.route = result.routes.first
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
}

// MARK: - AGSRouteTrackerDelegate

extension NavigateRouteWithReroutingViewController: AGSRouteTrackerDelegate {
    func routeTracker(_ routeTracker: AGSRouteTracker, didGenerateNewVoiceGuidance voiceGuidance: AGSVoiceGuidance) {
        setSpeakDirection(with: voiceGuidance.text)
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, didUpdate trackingStatus: AGSTrackingStatus) {
        updateTrackingStatusDisplay(routeTracker: routeTracker, status: trackingStatus)
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
            if status.currentManeuverIndex + 1 < directionsList.count {
                let nextDirection = directionsList[status.currentManeuverIndex + 1].directionText
                statusText.append("\nNext direction: \(nextDirection)")
            }
        case .reached:
            statusText = "Destination reached."
            routeAheadGraphic.geometry = nil
            routeTraveledGraphic.geometry = status.routeResult.routes.first?.routeGeometry
            mapView.locationDisplay.stop()
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
    
    func routeTrackerRerouteDidStart(_ routeTracker: AGSRouteTracker) {
        // speach stuff
    }
}


// MARK: - AGSLocationChangeHandlerDelegate

extension NavigateRouteWithReroutingViewController: AGSLocationChangeHandlerDelegate {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        // Update the tracker location with the new location from the simulated data source.
        routeTracker?.trackLocation(location)
    }
}

extension NavigateRouteWithReroutingViewController: XMLParserDelegate {
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String]) {
        //Only check for the lines that have a <trkpt> or <wpt> tag. The other lines don't have coordinates and thus don't interest us
        if elementName == "trkpt" || elementName == "wpt" {
            //Create a World map coordinate from the file
            let lat = Double(attributeDict["lat"]!)
            let lon = Double(attributeDict["lon"]!)
            let point = AGSPoint(x: lon!, y: lat!, spatialReference: .wgs84())
            gpxPoints.append(point)
        }
    }
}
