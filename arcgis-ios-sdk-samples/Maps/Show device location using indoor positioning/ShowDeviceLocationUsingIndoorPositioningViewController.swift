// Copyright 2022 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class ShowDeviceLocationUsingIndoorPositioningViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    /// The label to display location data source info.
    @IBOutlet var sourceStatusLabel: UILabel!
    /// The label to display beacons info.
    @IBOutlet var beaconStatusLabel: UILabel!
    
    /// The number formatter for status label.
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    /// The app-wide API key.
    let apiKey = AGSArcGISRuntimeEnvironment.apiKey
    /// A location data source based on sensor data (radio, GPS, motion sensors).
    var indoorsLocationDataSource: AGSIndoorsLocationDataSource?
    
    /// The current floor level reported by the indoors location data source.
    var currentFloor: NSNumber! {
        willSet(newValue) {
            if newValue != currentFloor {
                displayFeatures(floor: newValue)
            }
        }
    }
    
    /// Load an IPS-enabled web map from a portal.
    func makeMap() -> AGSMap {
        // Temporarily unset the API key for this sample.
        AGSArcGISRuntimeEnvironment.apiKey = ""
        
        // The portal that hosts the IPS-enabled map.
        let portal = AGSPortal(url: URL(string: "https://viennardc.maps.arcgis.com")!, loginRequired: true)
        // WARNING: Never hardcode login information in a production application.
        // This is done solely for the sake of the sample.
        let credential = AGSCredential(user: "tester_viennardc", password: "password.testing12345")
        portal.credential = credential
        // A floor-aware, IPS enabled web map for floors of Esri Building L in Redlands.
        let map = AGSMap(item: AGSPortalItem(portal: portal, itemID: "89f88764c29b48218366855d7717d266"))
        map.load { [weak self] error in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                self?.findPositioningTable(map: map)
            }
        }
        return map
    }
    
    /// Find the IPS positioning table to set up the location data source.
    func findPositioningTable(map: AGSMap) {
        let tables = map.tables as! [AGSServiceFeatureTable]
        loadTables(tables: tables) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure:
                self.presentAlert(error: SetupError.failedToLoadFeatureTables)
            case .success:
                if let featureTable = tables.first(where: { $0.tableName == "ips_positioning" }) {
                    self.setupIndoorsLocationDataSource(positioningTable: featureTable)
                } else {
                    self.presentAlert(error: SetupError.positioningTableNotFound)
                }
            }
        }
    }
    
    func setupIndoorsLocationDataSource(positioningTable: AGSServiceFeatureTable) {
        guard let map = mapView.map else { return }
        
        let queryParameters = AGSQueryParameters()
        guard let dateCreatedFieldName = positioningTable.fields.first(where: { $0.name.caseInsensitiveCompare("DateCreated") == .orderedSame || $0.name.caseInsensitiveCompare("Date_Created") == .orderedSame })?.name else {
            self.presentAlert(error: SetupError.dateCreatedFieldNotFound)
            return
        }
        queryParameters.orderByFields = [AGSOrderBy(fieldName: dateCreatedFieldName, sortOrder: .descending)]
        queryParameters.maxFeatures = 1
        #warning("test to see if this is required")
        queryParameters.whereClause = "1 = 1"
        
        positioningTable.queryFeatures(with: queryParameters) { [weak self] result, error in
            guard let self = self else { return }
            
            guard let result = result, error == nil else {
                self.presentAlert(error: SetupError.failedToLoadIPS)
                return
            }
            
            guard let feature = result.featureEnumerator().nextObject() else {
                self.presentAlert(error: SetupError.noIPSDataFound)
                return
            }
            
            // The ID that identifies a row in the positioning table. It is
            // possible to initialize ILDS without positioningID, in which case
            // the first row of the positioning table will be used.
            guard let globalID = feature.attributes[positioningTable.globalIDField] as? UUID else {
                self.presentAlert(error: SetupError.mapDoesNotSupportIPS)
                return
            }
            
            #warning("discuss with Shubham to see if keep it visible")
            let pathwaysLayer = (map.operationalLayers as! [AGSFeatureLayer]).first(where: { $0.name == "Pathways" })
            pathwaysLayer?.isVisible = false
            let pathwaysTable = pathwaysLayer?.featureTable as? AGSArcGISFeatureTable
            
            // Setting up `indoorsLocationDataSource` with positioning, pathways
            // tables and positioning ID.
            // - positioningTable: the "ips_positioning" feature table from an
            // IPS-enabled map.
            // - pathwaysTable: an `ArcGISFeatureTable` that contains pathways
            // as per the ArcGIS Indoors Information Model. Setting this
            // property enables path snapping of locations provided by the
            // `indoorsLocationDataSource`.
            // - positioningID: an ID which identifies a specific row in the
            // positioningTable that should be used for setting up IPS.
            let locationDataSource = AGSIndoorsLocationDataSource(positioningTable: positioningTable, pathwaysTable: pathwaysTable, positioningID: globalID)
            // The delegate which will receive location and status updates
            // from the data source.
            locationDataSource.locationChangeHandlerDelegate = self
            self.indoorsLocationDataSource = locationDataSource
            
            if let extent = pathwaysTable?.extent {
                self.mapView.setViewpointGeometry(extent)
            }
            self.mapView.locationDisplay.dataSource = locationDataSource
            self.mapView.locationDisplay.autoPanMode = .compassNavigation
            // Asynchronously start of the location display, which will in-turn
            // start `indoorsLocationDataSource` to receive IPS updates.
            self.mapView.locationDisplay.start { [weak self] (error) in
                guard let self = self, let error = error else { return }
                self.presentAlert(error: error)
            }
        }
    }
    
    /// A helper method to load one feature table at a time. Stop loading if
    /// error occurs.
    /// - Parameters:
    ///   - tables: The feature tables to load.
    ///   - completion: The load result for a table.
    func loadTables(tables: [AGSFeatureTable], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let table = tables.last else {
            completion(.success(()))
            return
        }
        table.load { [weak self] error in
            if let error = error {
                completion(.failure(error))
            } else {
                self?.loadTables(tables: tables.dropLast(), completion: completion)
            }
        }
    }
    
    /// Display features on a certain floor level using definition expression.
    /// - Parameter floor: The floor level of the features to be displayed.
    func displayFeatures(floor: NSNumber) {
        guard let layers = mapView.map?.operationalLayers as? [AGSLayer] else { return }
        for layer in layers {
            if layer.name == "Details" || layer.name == "Units" || layer.name == "Levels" {
                if let featureLayer = layer as? AGSFeatureLayer {
                    featureLayer.definitionExpression = "LEVEL_ID = \(floor)"
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["ShowDeviceLocationUsingIndoorPositioningViewController"]
    }
    
    deinit {
        // Stop location display, which in turn stop the data source.
        mapView.locationDisplay.stop()
        // Reset indoors location data source.
        indoorsLocationDataSource?.locationChangeHandlerDelegate = nil
        indoorsLocationDataSource = nil
        // Reset the API key.
        AGSArcGISRuntimeEnvironment.apiKey = apiKey
    }
}

extension ShowDeviceLocationUsingIndoorPositioningViewController: AGSLocationChangeHandlerDelegate {
    /// The delegate method to receive location updates from the data source.
    /// - Parameters:
    ///   - locationDataSource: The indoors location data source.
    ///   - location: The indoors location.
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        // warning: The floor property is not working in Esri building L, so not included in the UI.
        #warning("test to see if this is valid")
        let floor = location.additionalSourceProperties[.floor] as? NSNumber ?? NSNumber(value: Double.nan)
        let positionSource = location.additionalSourceProperties[.positionSource] as? String ?? "NA"
        let transmitterCount = location.additionalSourceProperties[AGSLocationSourcePropertyKey(rawValue: "transmitterCount")] ?? "NA"
        let satelliteCount = location.additionalSourceProperties[.satelliteCount] ?? "NA"
        let horizontalAccuracy = numberFormatter.string(from: NSNumber(value: location.horizontalAccuracy)) ?? "NA"
        
        // Vertical accuracy is always zero in our test, so we don't need to include it.
        let verticalAccuracy = numberFormatter.string(from: NSNumber(value: location.verticalAccuracy))
        
        currentFloor = floor
        
        let accuracyText = "Floor: \(floor), Position source: \(positionSource)"
        let beaconText = "\(transmitterCount) beacons, Horizontal accuracy: \(horizontalAccuracy)"
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sourceStatusLabel.text = accuracyText
            self.beaconStatusLabel.text = beaconText
        }
        // warning: Only for debugging.
        print(floor, positionSource, transmitterCount, satelliteCount, horizontalAccuracy, verticalAccuracy)
    }
    
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, statusDidChange status: AGSLocationDataSourceStatus) {
        switch status {
        case .starting, .started, .stopped:
            // - starting: it happens immediately after user starts the location
            // data source. It takes a while to completely start the ILDS.
            // - started: it happens once ILDS successfully started.
            // - stopped: ILDS may stop due to internal error, e.g. user revoked
            // the location permission in system settings. We don't handle these
            // error here.
            break
        case .failedToStart:
            // - failedToStart: This happens if user provides a wrong UUID, or
            // the positioning table has no entries, etc.
            DispatchQueue.main.async { [weak self] in
                if let error = locationDataSource.error {
                    self?.presentAlert(error: error)
                } else {
                    self?.presentAlert(title: "Fail to start ILDS", message: "ILDS failed to start due to an unknown error.")
                }
            }
        @unknown default:
            fatalError("Unknown location data source status.")
        }
    }
    
    private enum SetupError: LocalizedError {
        case dateCreatedFieldNotFound, failedToLoadFeatureTables, failedToLoadIPS, mapDoesNotSupportIPS, noIPSDataFound, positioningTableNotFound
        
        var errorDescription: String? {
            switch self {
            case .dateCreatedFieldNotFound:
                return "DateCreated filed is either missing or has a wrong name."
            case .failedToLoadFeatureTables:
                return "Failed to load feature tables."
            case .failedToLoadIPS:
                return "Failed to load IPS."
            case .mapDoesNotSupportIPS:
                return "Map does not support IPS."
            case .noIPSDataFound:
                return "No IPS data found."
            case .positioningTableNotFound:
                return "Positioning table not found."
            }
        }
    }
}
