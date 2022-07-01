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
    
    /// A URL to the temporary directory to store the exported tile packages.
    let temporaryDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString)
    var featureTable: AGSGeodatabaseFeatureTable?
    
    // MARK: Methods
    
    /// Get the URL to a portal item specific temporary directory.
    ///
    /// - Parameter itemID: The portal item ID.
    /// - Returns: A URL to the temporary directory.
    func getDownloadDirectoryURL(itemID: String) -> URL {
        let directoryURL = temporaryDirectoryURL.appendingPathComponent(itemID)
        // Create and return the full, unique URL to the temporary directory.
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }
    
//    required init?(coder: NSCoder) {
//        temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString)
//        try? FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: false)
//        vtpkTemporaryURL = temporaryDirectory
//            .appendingPathComponent("myTileCache", isDirectory: false)
//            .appendingPathExtension("vtpk")
//        styleTemporaryURL = temporaryDirectory
//            .appendingPathComponent("styleItemResources", isDirectory: true)
//        super.init(coder: coder)
//    }
    
    func closeGeodatabaseTapped() {
        
    }
    
    func createGeodatabase() {
        // Create the geodatabase file.
        let gdbPath = temporaryDirectoryURL.appendingPathComponent("LocationHistory.geodatabase")
        // Delete exisiting file if present from previous instance.
        if gdbPath.isFileURL {
            
        }
        AGSGeodatabase.create(withFileURL: gdbPath) { geodatabase, error in
            let tableDescription = AGSTableDescription(name: "LocationHistory", spatialReference: .wgs84(), geometryType: .point)
            tableDescription.hasAttachments = false
            tableDescription.hasM = false
            tableDescription.hasZ = false
            tableDescription.fieldDescriptions.add(AGSFieldDescription(name: "oid", fieldType: .OID))
            tableDescription.fieldDescriptions.add(AGSFieldDescription(name: "collection_timestamp", fieldType: .date))
            geodatabase?.createTable(with: tableDescription) { table, error in
                // Update UI with new table //////////
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
            // UPDATE TABLE////////
            // UPDATE FEATURES LABEL ///////
        }
    }
    
    func updateTable() {
        // Query all of the features in the feature table.
        featureTable?.queryFeatures(with: AGSQueryParameters()) { result, error in
            // Update the list of items with the results.
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createGeodatabase()
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "AuthenticateWithOAuthViewController"
        ]
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension CreateMobileGeodatabaseViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
    }
}
