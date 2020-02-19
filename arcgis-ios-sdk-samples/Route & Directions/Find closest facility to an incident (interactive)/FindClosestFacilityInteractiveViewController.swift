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
            mapView.graphicsOverlays.add(makeFacilitiesOverlay())
            mapView.graphicsOverlays.add(incidentGraphicsOverlay)
        }
    }

    // Create a closest facility task from the network service URL.
    private let closestFacilityTask: AGSClosestFacilityTask = {
        let networkServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/ClosestFacility")!
        return AGSClosestFacilityTask(url: networkServiceURL)
    }()
    
    // Create a graphic overlay to the map.
    private var incidentGraphicsOverlay = AGSGraphicsOverlay()
    
    // Create graphics to represent the route.
    private let routeSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 2.0)
    
    // Create an array of facilities in the area.
    private var facilities = [
        AGSFacility(point: AGSPoint(x: -1.3042129900625112E7, y: 3860127.9479775648, spatialReference: .webMercator())),
        AGSFacility(point: AGSPoint(x: -1.3042193400557665E7, y: 3862448.873041752, spatialReference: .webMercator())),
        AGSFacility(point: AGSPoint(x: -1.3046882875518233E7, y: 3862704.9896770366, spatialReference: .webMercator())),
        AGSFacility(point: AGSPoint(x: -1.3040539754780494E7, y: 3862924.5938606677, spatialReference: .webMercator())),
        AGSFacility(point: AGSPoint(x: -1.3042571225655518E7, y: 3858981.773018156, spatialReference: .webMercator())),
        AGSFacility(point: AGSPoint(x: -1.3039784633928463E7, y: 3856692.5980474586, spatialReference: .webMercator())),
        AGSFacility(point: AGSPoint(x: -1.3049023883956768E7, y: 3861993.789732541, spatialReference: .webMercator()))
    ]
    
    // Create the graphics and add them to the graphics overlay
    func makeFacilitiesOverlay() -> AGSGraphicsOverlay {
        let facilitySymbolURL = URL(string: "https://static.arcgis.com/images/Symbols/SafetyHealth/Hospital.png")!
        let facilitySymbol = AGSPictureMarkerSymbol(url: facilitySymbolURL)
        facilitySymbol.height = 30
        facilitySymbol.width = 30

        let graphicsOverlay = AGSGraphicsOverlay()
        graphicsOverlay.graphics.addObjects(from: facilities.map { AGSGraphic(geometry: $0.geometry, symbol: facilitySymbol) })
        return graphicsOverlay
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
                
                // Create a symbol for the incident.
                let incidentSymbol = AGSSimpleMarkerSymbol(style: .cross, color: .black, size: 20)
                
                // Remove previous graphics.
                self.incidentGraphicsOverlay.graphics.removeAllObjects()
                
                // Create a point and graphics for the incident.
                let graphic = AGSGraphic(geometry: mapPoint, symbol: incidentSymbol)
                self.incidentGraphicsOverlay.graphics.add(graphic)
                
                // Set the incident for the parameters.
                parameters.setIncidents([AGSIncident(point: mapPoint)])
                self.closestFacilityTask.solveClosestFacility(with: parameters) { [weak self] (result, error) in
                    guard let self = self else { return }
                    if let result = result {
                        // Get the ranked list of colsest facilities.
                        let rankedList = result.rankedFacilityIndexes(forIncidentIndex: 0)
                        
                        // Get the facility closest to the incident.
                         let closestFacility = rankedList?.first as! Int
                        
                        // Calculate the route based on the closest facility and chosen incident.
                        let route = result.route(forFacilityIndex: closestFacility, incidentIndex: 0)
                        
                        // Display the route graphics.
                        self.incidentGraphicsOverlay.graphics.add(AGSGraphic(geometry: route?.routeGeometry, symbol: self.routeSymbol))
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
