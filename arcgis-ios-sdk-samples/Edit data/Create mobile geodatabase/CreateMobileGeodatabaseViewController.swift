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
    @IBOutlet var createGeodatabaseBarButtonItem: UIBarButtonItem!
    @IBOutlet var closeShareBarButtonItem: UIBarButtonItem!
    @IBOutlet var featureCountLabel: UILabel!
    
    /// A URL to the temporary directory to store the exported tile packages.
    let temporaryGeodatabaseURL: URL
//    FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString)
    /// A directory to temporarily store all items.
    let temporaryDirectory: URL
    var geodatabase: AGSGeodatabase?
    var featureTable: AGSGeodatabaseFeatureTable?
    
    required init?(coder: NSCoder) {
        temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString)
        try? FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: false)
        temporaryGeodatabaseURL = temporaryDirectory
            .appendingPathComponent("LocationHistory", isDirectory: false)
            .appendingPathExtension("geodatabase")
        super.init(coder: coder)
    }
    
    // MARK: Methods
    
    @IBAction func closeAndShare(_ sender: UIBarButtonItem) {
//        if let geodatabase = geodatabase {
//            closeShareBarButtonItem.isEnabled = false
//            geodatabase.close()
//        }
        guard let geodatabase = geodatabase else { return }

        let activityViewController = UIActivityViewController(activityItems: [geodatabase], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true)
        activityViewController.completionWithItemsHandler = { _, completed, _, activityError in
            if completed {
                geodatabase.close()
            } else if let error = activityError {
                self.presentAlert(error: error)
            }
        }
    }
    
    @IBAction func createGeodatabase(_ sender: UIBarButtonItem) {
        // Create the geodatabase file.
//        let gdbPath = temporaryGeodatabaseURL.appendingPathComponent("LocationHistory.geodatabase")
        
        AGSGeodatabase.create(withFileURL: temporaryGeodatabaseURL) { [weak self] result, error in
            guard let self = self else { return }
            self.geodatabase = result
            let tableDescription = AGSTableDescription(name: "LocationHistory", spatialReference: .wgs84(), geometryType: .point)
            tableDescription.hasAttachments = false
            tableDescription.hasM = false
            tableDescription.hasZ = false
            tableDescription.fieldDescriptions.add(AGSFieldDescription(name: "oid", fieldType: .OID))
            tableDescription.fieldDescriptions.add(AGSFieldDescription(name: "collection_timestamp", fieldType: .date))
            self.geodatabase?.createTable(with: tableDescription) { table, error in
                print("create table success")
                self.queryfeatures()
                guard let table = table else { return }
                let featureLayer = AGSFeatureLayer(featureTable: table)
                self.mapView.map?.operationalLayers.add(featureLayer)
                self.featureTable = table
            }
        }
    }
    
    func addFeature(at mapPoint: AGSPoint) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let attributes = ["collectionTimeStamp": formatter.string(from: Date())]
        if let feature = featureTable?.createFeature(attributes: attributes, geometry: mapPoint) {
            featureTable?.add(feature)
            queryfeatures()
        }
    }
    
    func queryfeatures() {
        // Query all of the features in the feature table.
        featureTable?.queryFeatures(with: AGSQueryParameters()) { [weak self] result, error in
            if let result = result {
                let featureCount = result.featureEnumerator().allObjects.count
                // Update the list of items with the results.
                self?.featureCountLabel.text = String(format: "Number of features added: %@", featureCount)
            } else if let error = error {
                self?.presentAlert(error: error)
            }
        }
    }
    
    deinit {
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        createGeodatabase()
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "AuthenticateWithOAuthViewController"
        ]
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension CreateMobileGeodatabaseViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        addFeature(at: mapPoint)
    }
}
