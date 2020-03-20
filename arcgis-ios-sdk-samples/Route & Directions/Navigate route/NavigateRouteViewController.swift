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
import AVFoundation

class NavigateRouteViewController: UIViewController {
    /// The route result solved by the route task.
    var routeResult: AGSRouteResult!
    /// The original view point that can be reset to later on.
    var defaultViewPoint: AGSViewpoint?
    /// The graphics overlay for the polygon and points.
    let graphicsOverlay = AGSGraphicsOverlay()
    /// The  graphic (with a dashed line symbol) to represent the route ahead.
    let routeAheadGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .dash, color: .systemPurple, width: 5), attributes: nil)
    /// The graphic to represent the route that's been traveled (initially empty).
    let routeTraveledGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .solid, color: .systemBlue, width: 3), attributes: nil)
    
    // meici bian
    /// A list to keep track of directions solved by the route task.
    var directionsList: [AGSDirectionManeuver]?
    /// The route tracker for navigation.
    var routeTracker: AGSRouteTracker?
    /// An AVSpeechSynthesizer for text to speech.
    var speechSynthesizer: AVSpeechSynthesizer?
    
    // yici
    /// The route task to solve the route between stops, using the online routing service.
    var routeTask: AGSRouteTask!
    
    /// The bar button item that initiates the create convex hull operation.
    @IBOutlet weak var navigateButtonItem: UIBarButtonItem!
    /// The bar button item that removes the convex hull as well as the MapPoints.
    @IBOutlet weak var resetButtonItem: UIBarButtonItem!
    /// The bar button item that recenters the map to navigation pan mode.
    @IBOutlet weak var recenterButtonItem: UIBarButtonItem!
    /// The 3-line label to display navigation status.
    @IBOutlet weak var statusLabel: UILabel!
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.graphicsOverlays.add(graphicsOverlay)
        }
    }
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .navigationVector())
        // Solve the route as map loads.
        self.getDefaultParameters { (params: AGSRouteParameters) in
            self.solveRoute(params)
        }
        return map
    }
    
    func makeStops() -> [AGSStop] {
        let stop1 = AGSStop(point: AGSPoint(x: -117.160386727, y: 32.706608, spatialReference: AGSSpatialReference.wgs84()))
        stop1.name = "San Diego Convention Center"
        let stop2 = AGSStop(point: AGSPoint(x: -117.173034, y: 32.712329, spatialReference: AGSSpatialReference.wgs84()))
        stop2.name = "USS San Diego Memorial"
        let stop3 = AGSStop(point: AGSPoint(x: -117.147230, y: 32.730467, spatialReference: AGSSpatialReference.wgs84()))
        stop3.name = "RH Fleet Aerospace Museum"
        return [stop1, stop2, stop3]
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
                params.setStops(self.makeStops())
                completion(params)
            }
        }
    }
    
    func solveRoute(_ params: AGSRouteParameters) {
        routeTask!.solveRoute(with: params) { (routeResult: AGSRouteResult?, error: Error?) in
            if let error = error {
                self.presentAlert(error: error)
            } else if let result = routeResult {
                self.routeResult = result
                self.setDataSource(result)
                self.setRouteTracker(result)
                self.setRouteGraphics(result)
                self.setSpeechSynthesizer()
                // Enable bar button item.
                self.navigateButtonItem.isEnabled = true
            }
        }
    }
    
    func setSpeechSynthesizer() {
        speechSynthesizer = AVSpeechSynthesizer()
    }
    
    func setDataSource(_ result: AGSRouteResult) {
        // datasource should not be time-dependent
        if let route = result.routes.first {
            directionsList = route.directionManeuvers
            let mockDataSource = AGSSimulatedLocationDataSource()
            let densifiedRoute = AGSGeometryEngine.geodeticDensifyGeometry(route.routeGeometry!, maxSegmentLength: 50.0, lengthUnit: .meters(), curveType: .geodesic) as! AGSPolyline
            mockDataSource.setLocationsWith(densifiedRoute)
            mockDataSource.locationChangeHandlerDelegate = self
            mapView.locationDisplay.dataSource = mockDataSource
        }
    }
    
    func setRouteTracker(_ result: AGSRouteResult) {
        routeTracker = AGSRouteTracker(routeResult: result, routeIndex: 0)
        routeTracker?.delegate = self
    }
    
    func setRouteGraphics(_ result: AGSRouteResult) {
        if let route = result.routes.first {
            let stopSymbol = AGSSimpleMarkerSymbol(style: .diamond, color: .orange, size: 20)
            for stop in self.makeStops() {
                graphicsOverlay.graphics.add(AGSGraphic(geometry: stop.geometry, symbol: stopSymbol))
            }
            // Show the resulting route on the map and save a reference to the route.
            routeAheadGraphic.geometry = route.routeGeometry
            routeTraveledGraphic.geometry = nil
            graphicsOverlay.graphics.addObjects(from: [
                routeAheadGraphic,
                routeTraveledGraphic
            ])
            if let routeGeometry = route.routeGeometry {
                if let viewPoint = defaultViewPoint {
                    self.mapView.setViewpoint(viewPoint, completion: nil)
                } else {
                    mapView.setViewpointGeometry(routeGeometry) { _ in
                        // Get the zoomed view point.
                        self.defaultViewPoint = self.mapView.currentViewpoint(with: .centerAndScale)
                    }
                }
            }
        }
    }
    
    /// Called in response to the Navigate button being tapped.
    @IBAction func startNavigation() {
        navigateButtonItem.isEnabled = false
        resetButtonItem.isEnabled = true
        mapView.locationDisplay.autoPanMode = .navigation
        // If the user navigates the map view away from the location display, activate the recenter button.
        mapView.locationDisplay.autoPanModeChangedHandler = { _ in self.recenterButtonItem.isEnabled = true }
        // Start the location data source and location display.
        mapView.locationDisplay.start(completion: nil)
    }
    
    /// Called in response to the Reset button being tapped.
    @IBAction func reset() {
        // stop the speech, if any
        speechSynthesizer?.stopSpeaking(at: .immediate)
        speechSynthesizer = nil
        // stop the datasource generation, if there is any.
        mapView.locationDisplay.stop()
        mapView.locationDisplay.autoPanMode = .off
        graphicsOverlay.graphics.removeAllObjects()
        directionsList = nil
        setDataSource(routeResult)
        setRouteTracker(routeResult)
        setRouteGraphics(routeResult)
        setSpeechSynthesizer()
        recenterButtonItem.isEnabled = false
        resetButtonItem.isEnabled = false
        navigateButtonItem.isEnabled = true
    }
    
    /// Called in response to the Recenter button being tapped.
    @IBAction func recenter() {
        mapView.locationDisplay.autoPanMode = .navigation
        recenterButtonItem.isEnabled = false
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["NavigateRouteViewController"]
    }
    
    deinit {
        print("deinit")
        speechSynthesizer = nil
        routeTracker = nil
        // will test more
    }
}

extension NavigateRouteViewController: AGSRouteTrackerDelegate {
    func routeTracker(_ routeTracker: AGSRouteTracker, didGenerateNewVoiceGuidance voiceGuidance: AGSVoiceGuidance) {
        setSpeakDirection(voiceGuidance.text)
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, didUpdate trackingStatus: AGSTrackingStatus) {
        // Call the base method for LocationDataSource to update the location with the tracked (snapped to route) location.
        // let location = trackingStatus.displayLocation
        updateTrackingStatus(trackingStatus)
    }
    
    func setSpeakDirection(_ text: String?) {
        speechSynthesizer?.stopSpeaking(at: AVSpeechBoundary.word)
        if let text = text {
            let speechUtterance = AVSpeechUtterance(string: text)
            speechUtterance.rate = AVSpeechUtteranceMaximumSpeechRate / 2.0
            speechSynthesizer?.speak(speechUtterance)
        }
    }
    
    func updateTrackingStatus(_ status: AGSTrackingStatus) {
        var statusText: String
        switch status.destinationStatus {
        case .notReached, .approaching:
            let distanceRemaining = status.routeProgress.remainingDistance.displayText + " " + status.routeProgress.remainingDistance.displayTextUnits.pluralDisplayName
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .full
            let timeRemaining = formatter.string(from: TimeInterval(status.routeProgress.remainingTime * 60))!
            statusText = "Distance remaining: \(distanceRemaining)\nTime remaining: \(timeRemaining)\n"
            if status.currentManeuverIndex < directionsList!.count {
                let nextDirection = directionsList![status.currentManeuverIndex + 1].directionText
                statusText.append("Next direction: \(nextDirection)")
            }
            routeAheadGraphic.geometry = status.routeProgress.remainingGeometry
            routeTraveledGraphic.geometry = status.routeProgress.traversedGeometry
        case .reached:
            routeAheadGraphic.geometry = nil
            routeTraveledGraphic.geometry = status.routeProgress.traversedGeometry
            if status.remainingDestinationCount > 1 {
                statusText = "Intermediate stop reached."
                routeTracker?.switchToNextDestination(completion: nil)
            } else {
                statusText = "Final destination reached."
                mapView.locationDisplay.dataSource.stop()
            }
        default:
            return
        }
        // Update label text.
        self.statusLabel.text = statusText
    }
}

extension NavigateRouteViewController: AGSLocationChangeHandlerDelegate {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        // Update the tracker location with the new location from the simulated data source.
        self.routeTracker?.trackLocation(location, completion: nil)
    }
}

// questions
// 1. reset button
// 2. too fast in location changes for simulated timer 1s per location, 58 in total - control by densify
// 3. label blend with dev text
// 4. u-turn voice
// avoid the reset animation of origin
