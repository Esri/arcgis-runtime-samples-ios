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
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            mapView.setViewpoint(AGSViewpoint(latitude: 39.323845, longitude: -77.733201, scale: 10000))
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
    }
    
    // MARK: Methods
    
    @IBAction func closeAndShare(_ sender: UIBarButtonItem) {
        if let geodatabase = geodatabase {
            geodatabase.close()
        }
        let activityViewController = UIActivityViewController(activityItems: [temporaryGeodatabaseURL], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true)
        activityViewController.completionWithItemsHandler = { guess, completed, what, activityError in
            self.createGeodatabase()
//            if completed {
//                self.createGeodatabase()
//            } else if let error = activityError {
//                self.presentAlert(error: error)
//            }
        }
    }
    
    func createGeodatabase() {
        resetMap()
        if FileManager.default.fileExists(atPath: temporaryGeodatabaseURL.path) {
            do {
                try FileManager.default.removeItem(at: temporaryGeodatabaseURL)
            } catch {
                presentAlert(title: "File already exists")
            }
        }
        AGSGeodatabase.create(withFileURL: temporaryGeodatabaseURL) { [weak self] result, error in
            guard let self = self else { return }
            self.geodatabase = result
            let tableDescription = AGSTableDescription(name: "LocationHistory", spatialReference: .wgs84(), geometryType: .point)
            let fieldDescriptions = [
                AGSFieldDescription(name: "oid", fieldType: .OID),
                AGSFieldDescription(name: "collection_timestamp", fieldType: .date)
            ]
            tableDescription.fieldDescriptions.addObjects(from: fieldDescriptions)
            tableDescription.hasAttachments = false
            tableDescription.hasM = false
            tableDescription.hasZ = false
            self.geodatabase?.createTable(with: tableDescription) { table, error in
                print("create table success")
                if let table = table {
                    table.load() { _ in
                        self.featureTable = table
                        let featureLayer = AGSFeatureLayer(featureTable: table)
                        self.mapView.map?.operationalLayers.add(featureLayer)
                        self.featureCountLabel.text = "Number of features added: 0"
                    }
                } else if let error = error {
                    self.presentAlert(error: error)
                }
            }
        }
    }
    
    func addFeature(at mapPoint: AGSPoint) {
        let currentDate = Date()
        var attributes = [String: Date]()
        attributes["collection_timestamp"] = currentDate
        guard let feature = featureTable?.createFeature(attributes: attributes, geometry: mapPoint) else { return }
            featureTable?.add(feature) { [weak self] error in
                guard let self = self else { return }
                let numberOfFeatures = self.featureTable?.numberOfFeatures ?? 0
                let featureCount = String(numberOfFeatures)
                self.featureCountLabel.text = String(format: "Number of features added: %@", featureCount)
                self.viewTableBarButtonItem.isEnabled = true
                if let error = error {
                    self.presentAlert(error: error)
                }
            }
    }
    
    func resetMap() {
        if mapView.map?.loadStatus == .loaded {
            mapView.map?.operationalLayers.removeAllObjects()
            viewTableBarButtonItem.isEnabled = false
            createGeodatabase()
        } else if let error = mapView.map?.loadError {
            presentAlert(error: error)
        }
    }
    
    deinit {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }
    
    // MARK: UIViewController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController,
           let controller = navigationController.topViewController as? MobileGeodatabaseTableViewController {
            featureTable?.queryFeatures(with: AGSQueryParameters()) { [weak self] results, error in
                guard let self = self else { return }
                if let results = results {
                    let features = results.featureEnumerator().allObjects
                    let oidArray = features.compactMap { $0.attributes["oid"] as? Int }
                    controller.oidArray = oidArray
                    let timeStampArray = features.compactMap { $0.attributes["collection_timestamp"] as? Date }
                    controller.collectionTimeStamps = timeStampArray
                } else if let error = error {
                    self.presentAlert(error: error)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createGeodatabase()
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
