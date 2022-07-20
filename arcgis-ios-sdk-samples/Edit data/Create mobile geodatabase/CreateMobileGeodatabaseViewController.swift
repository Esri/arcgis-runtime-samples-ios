// Copyright 2022 Esri.
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

class CreateMobileGeodatabaseViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Create a map with the topographic basemap.
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            // Set the viewpoint.
            mapView.setViewpoint(AGSViewpoint(latitude: 39.323845, longitude: -77.733201, scale: 10_000))
            // Set the touch delegate.
            mapView.touchDelegate = self
        }
    }
    
    @IBOutlet var viewTableBarButtonItem: UIBarButtonItem!
    @IBOutlet var createShareBarButtonItem: UIBarButtonItem!
    @IBOutlet var featureCountLabel: UILabel!
    
    /// A URL to the temporary geodatabase.
    let temporaryGeodatabaseURL: URL
    /// A directory to temporarily store the geodatabase.
    let temporaryDirectory: URL
    /// The mobile geodatabase.
    var geodatabase: AGSGeodatabase?
    /// The feature table created along with the geodatabase.
    var featureTable: AGSGeodatabaseFeatureTable?
    
    required init?(coder: NSCoder) {
        // Create the temporary directory.
        temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString)
        try? FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: false)
        // Create the geodatabase path.
        temporaryGeodatabaseURL = temporaryDirectory
            .appendingPathComponent("LocationHistory", isDirectory: false)
            .appendingPathExtension("geodatabase")
        super.init(coder: coder)
        // Create the initial geodatabase.
        createGeodatabase()
    }
    
    // MARK: Methods
    
    /// Prompt options to share the geodatabase.
    @IBAction func closeAndShare(_ sender: UIBarButtonItem) {
        // Create the activity view controller with the geodatabase URL.
        let activityViewController = UIActivityViewController(activityItems: [temporaryGeodatabaseURL], applicationActivities: nil)
        // Set the popover presentation.
        activityViewController.popoverPresentationController?.barButtonItem = sender
        // Present the activity view controller.
        present(activityViewController, animated: true)
        // Reset the map's state once the geodatabase has been shared.
        activityViewController.completionWithItemsHandler = { [weak self] _, completed, _, activityError in
            if completed {
                self?.resetMap()
            } else if let error = activityError {
                self?.presentAlert(error: error)
            }
        }
    }
    
    /// Query features when the "View table" button is tapped.
    @IBAction func queryFeatures() {
        guard let featureTable = featureTable else { return }
        let navigationController = storyboard!.instantiateViewController(withIdentifier: "NavigationController") as! UINavigationController
        let mobileGeodatabaseController = navigationController.viewControllers.first as! MobileGeodatabaseTableViewController
        featureTable.queryFeatures(with: AGSQueryParameters()) { [weak self] results, error in
            guard let self = self else { return }
            if let results = results {
                let features = results.featureEnumerator().allObjects
                // Create an array of each feature's OID.
                mobileGeodatabaseController.oidArray = features.compactMap { $0.attributes["oid"] as? Int }
                // Create an array of each feature's time stamps.
                mobileGeodatabaseController.collectionTimeStamps = features.compactMap { $0.attributes["collection_timestamp"] as? Date }
                self.present(navigationController, animated: true)
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    
    // Create the mobile geodatabase.
    func createGeodatabase() {
        // Remove the file if it already exists.
        if FileManager.default.fileExists(atPath: temporaryGeodatabaseURL.path) {
            do {
                try FileManager.default.removeItem(at: temporaryGeodatabaseURL)
            } catch {
                presentAlert(title: "File already exists")
            }
        }
        // Create the mobile geodatabase at the given URL.
        AGSGeodatabase.create(withFileURL: temporaryGeodatabaseURL) { [weak self] result, error in
            guard let self = self else { return }
            self.geodatabase = result
            // Create a description for the feature table.
            let tableDescription = AGSTableDescription(name: "LocationHistory", spatialReference: .wgs84(), geometryType: .point)
            // Create and add the description fields for the table.z
            // `AGSFieldType.OID` is the primary key of the SQLite table.
            // `AGSFieldType.DATE` is a date column used to store a Calendar date.
            // `AGSFieldDescription`s can be a SHORT, INTEGER, GUID, FLOAT, DOUBLE, DATE, TEXT, OID, GLOBALID, BLOB, GEOMETRY, RASTER, or XML.
            let fieldDescriptions = [
                AGSFieldDescription(name: "oid", fieldType: .OID),
                AGSFieldDescription(name: "collection_timestamp", fieldType: .date)
            ]
            tableDescription.fieldDescriptions.addObjects(from: fieldDescriptions)
            // Set any unnecessary properties to false.
            tableDescription.hasAttachments = false
            tableDescription.hasM = false
            tableDescription.hasZ = false
            // Add a new table to the geodatabase by creating one from the table description.
            self.geodatabase?.createTable(with: tableDescription) { table, error in
                if let table = table {
                    // Load the table.
                    table.load { _ in
                        self.featureTable = table
                        // Create a feature layer using the table.
                        let featureLayer = AGSFeatureLayer(featureTable: table)
                        // Add the feature layer to the map's operational layers.
                        self.mapView.map?.operationalLayers.add(featureLayer)
                        self.featureCountLabel.text = "Number of features added: 0"
                    }
                } else if let error = error {
                    self.presentAlert(error: error)
                }
            }
        }
    }
    
    /// Add a feature at the provided map point.
    func addFeature(at mapPoint: AGSPoint) {
        // Create an attribute with the current date.
        let attributes = ["collection_timestamp": Date()]
        guard let featureTable = featureTable else { return }
        // Create a feature with the created attribute and geometry.
        let feature = featureTable.createFeature(attributes: attributes, geometry: mapPoint)
        // Add the feature to the feature table.
        featureTable.add(feature) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                let featureCount = String(featureTable.numberOfFeatures)
                // Update the label's text to display the current number of features.
                self.featureCountLabel.text = String(format: "Number of features added: %@", featureCount)
                // Enable the view table bar button item.
                self.viewTableBarButtonItem.isEnabled = true
            }
        }
    }
    
    /// Remove existing operational layers and close the geodatabase.
    func resetMap() {
        if let geodatabase = geodatabase {
            // Close the geodatabase to cease all adjustments.
            geodatabase.close()
            // Remove the current feature layers.
            mapView.map?.operationalLayers.removeAllObjects()
            // Reset the button's state.
            viewTableBarButtonItem.isEnabled = false
            // Create a new mobile geodatabase.
            createGeodatabase()
        }
    }
    
    deinit {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "CreateMobileGeodatabaseViewController",
            "MobileGeodatabaseTableViewController"
        ]
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension CreateMobileGeodatabaseViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        addFeature(at: mapPoint)
    }
}
