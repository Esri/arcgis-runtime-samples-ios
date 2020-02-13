//
// Copyright © 2020 Esri.
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
//

import UIKit
import ArcGIS

class FindClosestFacilityInteractiveViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Initialize the map.
            mapView.map = AGSMap(basemapType: .streets, latitude: 32.727, longitude: -117.1750, levelOfDetail: 12)
            mapView.touchDelegate = self
            
            // Create symbols and graphics to add to the graphic overlays.
            createFacilitiesAndGraphics()
            mapView.graphicsOverlays.add(facilityGraphicsOverlay)
            mapView.graphicsOverlays.add(incidentGraphicsOverlay)
        }
    }
    
    private let facilityURL = URL(string: "https://static.arcgis.com/images/Symbols/SafetyHealth/Hospital.png")!
    
    // Add graphic overlays to the map.
    private var facilityGraphicsOverlay = AGSGraphicsOverlay()
    private var incidentGraphicsOverlay = AGSGraphicsOverlay()
    
    // Create a closest facility task from the network service URL.
    private let closestFacilityTask: AGSClosestFacilityTask = {
        let networkServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/ClosestFacility")!
        return AGSClosestFacilityTask(url: networkServiceURL)
    }()
    
    // Create an array of facilities in the area.
    private var facilities = [AGSFacility]()
    // Create graphics to represent the route.
    private let routeSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 2.0)
    
    // Add the facilities and create graphics.
    private func createFacilitiesAndGraphics() {
        facilities = [
            AGSFacility(point: AGSPoint(x: -1.3042129900625112E7, y: 3860127.9479775648, spatialReference: .webMercator())),
            AGSFacility(point: AGSPoint(x: -1.3042193400557665E7, y: 3862448.873041752, spatialReference: .webMercator())),
            AGSFacility(point: AGSPoint(x: -1.3046882875518233E7, y: 3862704.9896770366, spatialReference: .webMercator())),
            AGSFacility(point: AGSPoint(x: -1.3040539754780494E7, y: 3862924.5938606677, spatialReference: .webMercator())),
            AGSFacility(point: AGSPoint(x: -1.3042571225655518E7, y: 3858981.773018156, spatialReference: .webMercator())),
            AGSFacility(point: AGSPoint(x: -1.3039784633928463E7, y: 3856692.5980474586, spatialReference: .webMercator())),
            AGSFacility(point: AGSPoint(x: -1.3049023883956768E7, y: 3861993.789732541, spatialReference: .webMercator()))]
        let facilitySymbol = AGSPictureMarkerSymbol(url: facilityURL)
        facilitySymbol.height = 30
        facilitySymbol.width = 30
        
        for eachFacility in facilities {
            facilityGraphicsOverlay.graphics.add(AGSGraphic(geometry: eachFacility.geometry, symbol: facilitySymbol, attributes: .none))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FindClosestFacilityInteractiveViewController"]
    }
}

// MARK: - AGSGeoViewTouchDelegate
extension FindClosestFacilityInteractiveViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Find the closest facilities with the default parameters.
        closestFacilityTask.defaultClosestFacilityParameters { [weak self] (parameters, error) in
            guard let self = self else { return }
            if let parameters = parameters {
                parameters.setFacilities(self.facilities)
                let incidentSymbol = AGSSimpleMarkerSymbol(style: .cross, color: .black, size: 20)
                
                // Remove previous graphics.
                self.incidentGraphicsOverlay.graphics.removeAllObjects()
                
                // Create point and graphics of the incident.
                let incidentPoint = AGSPoint(x: mapPoint.x, y: mapPoint.y, spatialReference: .webMercator())
                let graphic = AGSGraphic(geometry: incidentPoint, symbol: incidentSymbol, attributes: .none)
                self.incidentGraphicsOverlay.graphics.add(graphic)
                
                parameters.setIncidents([AGSIncident(point: incidentPoint)])
                self.closestFacilityTask.solveClosestFacility(with: parameters) { [weak self] (result, error) in
                    guard let self = self else { return }
                    if let result = result {
                        let rankedList = result.rankedFacilityIndexes(forIncidentIndex: 0)
                        let closestFacility = Int(truncating: (rankedList?[0])!)
                        let route = result.route(forFacilityIndex: closestFacility, incidentIndex: 0)
                        self.incidentGraphicsOverlay.graphics.add(AGSGraphic(geometry: route?.routeGeometry, symbol: self.routeSymbol, attributes: .none))
                    } else if let error = error {
                        self.presentAlert(error: error)
                    }
                }
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
}
