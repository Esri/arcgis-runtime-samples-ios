//
// Copyright © 2019 Esri.
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

/// A view controller that manages the interface of the Find Closest Facility to
/// Multiple Incidents (Service) sample.
class FindClosestFacilityMultipleIncidentsServiceViewController: UIViewController {
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.graphicsOverlays.add(routesOverlay)
        }
    }
    /// The bar button item that initiates the solve route operation.
    @IBOutlet weak var solveRoutesButtonItem: UIBarButtonItem!
    /// The bar button item that removes the solved routes.
    @IBOutlet weak var resetButtonItem: UIBarButtonItem!
    
    /// The graphics overlay for the routes.
    let routesOverlay = AGSGraphicsOverlay()
    
    /// The facility features.
    var facilityFeatures = [AGSFeature]()
    /// The incident features.
    var incidentFeatures = [AGSFeature]()
    /// The task used to find the closest facilities.
    let closestFacilityTask: AGSClosestFacilityTask = {
        let url = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NetworkAnalysis/SanDiego/NAServer/ClosestFacility")!
        return AGSClosestFacilityTask(url: url)
    }()
    
    /// Creates a feature layer with the facilities. It is configured to render
    /// the facilities using a fire station image.
    ///
    /// - Returns: A new `AGSFeatureLayer` object.
    func makeFacilitiesLayer() -> AGSFeatureLayer {
        let facilitiesTableURL = URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/San_Diego_Facilities/FeatureServer/0")!
        let facilitiesTable = AGSServiceFeatureTable(url: facilitiesTableURL)
        let facilitiesLayer = AGSFeatureLayer(featureTable: facilitiesTable)
        
        let facilityImageURL = URL(string: "https://static.arcgis.com/images/Symbols/SafetyHealth/FireStation.png")!
        let facilitySymbol = AGSPictureMarkerSymbol(url: facilityImageURL)
        facilitySymbol.width = 30
        facilitySymbol.height = 30
        facilitiesLayer.renderer = AGSSimpleRenderer(symbol: facilitySymbol)
        
        return facilitiesLayer
    }
    
    /// Creates a feature layer with the incidents. It is configured to render
    /// the incidents using a fire image.
    ///
    /// - Returns: A new `AGSFeatureLayer` object.
    func makeIncidentsLayer() -> AGSFeatureLayer {
        let incidentsTableURL = URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/San_Diego_Incidents/FeatureServer/0")!
        let incidentsTable = AGSServiceFeatureTable(url: incidentsTableURL)
        let incidentsLayer = AGSFeatureLayer(featureTable: incidentsTable)
        
        let incidentsImageURL = URL(string: "https://static.arcgis.com/images/Symbols/SafetyHealth/esriCrimeMarker_56_Gradient.png")!
        let incidentsSymbol = AGSPictureMarkerSymbol(url: incidentsImageURL)
        incidentsSymbol.width = 30
        incidentsSymbol.height = 30
        incidentsLayer.renderer = AGSSimpleRenderer(symbol: incidentsSymbol)
        
        return incidentsLayer
    }
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .streetsWithReliefVector())
        
        let facilitiesLayer = makeFacilitiesLayer()
        let incidentsLayer = makeIncidentsLayer()
        map.operationalLayers.addObjects(from: [facilitiesLayer, incidentsLayer])
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        queryAllFeatures(from: facilitiesLayer.featureTable!) { [weak self] (result) in
            switch result {
            case .success(let features):
                self?.facilityFeatures = features
            case .failure(let error):
                self?.presentAlert(error: error)
            }
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        queryAllFeatures(from: incidentsLayer.featureTable!) { [weak self] (result) in
            switch result {
            case .success(let features):
                self?.incidentFeatures = features
            case .failure(let error):
                self?.presentAlert(error: error)
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let strongSelf = self else { return }
            
            let geometries = (strongSelf.facilityFeatures + strongSelf.incidentFeatures).compactMap { $0.geometry }
            if let extent = AGSGeometryEngine.combineExtents(ofGeometries: geometries) {
                strongSelf.mapView.setViewpointGeometry(extent, padding: 20)
            }
            
            strongSelf.solveRoutesButtonItem.isEnabled = true
        }
        
        return map
    }
    
    /// Queries for all the features from a given feature table.
    ///
    /// - Parameters:
    ///   - featureTable: The feature table whose features should be queried.
    ///   - completion: A closure executed upon success or failure.
    func queryAllFeatures(from featureTable: AGSFeatureTable, completion: @escaping (Result<[AGSFeature], Error>) -> Void) {
        featureTable.load { [unowned featureTable] (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                let queryParameters = AGSQueryParameters()
                queryParameters.whereClause = "1=1"
                featureTable.queryFeatures(with: queryParameters) { (result, error) in
                    if let result = result {
                        completion(.success(result.featureEnumerator().allObjects))
                    } else if let error = error {
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    /// Called in response to the Solve Routes button being tapped.
    @IBAction func solveRoutes() {
        solveRoutesButtonItem.isEnabled = false
        closestFacilityTask.defaultClosestFacilityParameters { [weak self] (parameters, error) in
            guard let self = self else { return }
            if let parameters = parameters {
                self.didGetClosestFacilityParameters(parameters)
            } else if let error = error {
                self.presentAlert(error: error)
                self.solveRoutesButtonItem.isEnabled = true
            }
        }
    }
    
    /// Called in response to the default closest facility paremters being
    /// generated successfully.
    ///
    /// - Parameter parameters: The parameters that were generated.
    func didGetClosestFacilityParameters(_ parameters: AGSClosestFacilityParameters) {
        let facilities = facilityFeatures.lazy
            .compactMap { $0.geometry as? AGSPoint }
            .map(AGSFacility.init(point:))
        parameters.setFacilities(Array(facilities))
        let incidents = incidentFeatures.lazy
            .compactMap { $0.geometry as? AGSPoint }
            .map(AGSIncident.init(point:))
        parameters.setIncidents(Array(incidents))
        self.closestFacilityTask.solveClosestFacility(with: parameters) { [weak self] (result, error) in
            guard let self = self else { return }
            if let result = result {
                self.didSolveClosestFacility(with: result)
            } else if let error = error {
                self.presentAlert(error: error)
                self.solveRoutesButtonItem.isEnabled = true
            }
        }
    }
    
    /// Called in response to the closest facility having been solved
    /// successfully.
    ///
    /// - Parameter result: The result of the solve closest facility operation.
    func didSolveClosestFacility(with result: AGSClosestFacilityResult) {
        // Create a graphic for the closest route to each facility.
        let routeGraphics = result.incidents.indices.compactMap { (incidentIndex) -> AGSGraphic? in
            guard let closestFacilityIndex = result.rankedFacilityIndexes(forIncidentIndex: incidentIndex)?.first as? Int else {
                return nil
            }
            
            let closestFacilityRoute = result.route(forFacilityIndex: closestFacilityIndex, incidentIndex: incidentIndex)
            let symbol = AGSSimpleLineSymbol(style: .solid, color: UIColor(red: 0, green: 0, blue: 1, alpha: 77 / 255), width: 5)
            return AGSGraphic(geometry: closestFacilityRoute?.routeGeometry, symbol: symbol)
        }
        // Add the graphics to the overlay.
        routesOverlay.graphics.addObjects(from: routeGraphics)
        resetButtonItem.isEnabled = true
    }
    
    /// Called in response to the Reset button being tapped.
    @IBAction func reset() {
        routesOverlay.graphics.removeAllObjects()
        
        resetButtonItem.isEnabled = false
        solveRoutesButtonItem.isEnabled = true
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "FindClosestFacilityMultipleIncidentsServiceViewController"
        ]
    }
}
