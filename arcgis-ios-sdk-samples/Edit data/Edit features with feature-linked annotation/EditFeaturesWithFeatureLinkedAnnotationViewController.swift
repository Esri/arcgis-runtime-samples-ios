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

import UIKit
import ArcGIS

class EditFeaturesWithFeatureLinkedAnnotationViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            // Create the map with a light gray canvas basemap centered on Loudoun, Virginia.
            mapView.map = AGSMap(basemapType: .lightGrayCanvasVector, latitude: 39.0204, longitude: -77.4159, levelOfDetail: 18)
            // Set the touch delegate.
            mapView.touchDelegate = self
        }
    }
    // The geodatabase used by this sample.
    let geodatabase: AGSGeodatabase!
    // The feature that has been selected.
    var selectedFeature: AGSFeature?
    // The returned cancelable after identifying the layers.
    var identifyOperation: AGSCancelable?
    
    required init?(coder: NSCoder) {
        // Create a URL leading to the resource.
        let geodatabaseURL = Bundle.main.url(forResource: "loudoun_anno", withExtension: "geodatabase")!
        do {
            // Create a temporary directory URL.
            let temporaryDirectoryURL = try FileManager.default.url(
                for: .itemReplacementDirectory,
                in: .userDomainMask,
                appropriateFor: geodatabaseURL,
                create: true
            )
            // Create a temporary URL where the geodatabase URL can be copied to.
            let temporaryGeodatabaseURL = temporaryDirectoryURL.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
            try FileManager.default.copyItem(at: geodatabaseURL, to: temporaryGeodatabaseURL)
            // Create the geodatabase with the URL.
            geodatabase = AGSGeodatabase(fileURL: temporaryGeodatabaseURL)
        } catch {
            print("Error setting up geodatabase: \(error)")
            geodatabase = nil
        }
        
        super.init(coder: coder)
        
        // Load the geodatabase.
        geodatabase?.load { [weak self] (error) in
            let result: Result<Void, Error>
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(())
            }
            self?.geodatabaseDidLoad(with: result)
        }
    }
    
    deinit {
        if let geodatabase = geodatabase {
            geodatabase.close()
            try? FileManager.default.removeItem(at: geodatabase.fileURL)
        }
    }
    
    // Called in response to the geodatabase load operation completing.
    func geodatabaseDidLoad(with result: Result<Void, Error>) {
        switch result {
        case .success:
            guard let map = self.mapView.map else { return }
            // Create feature layers from tables in the geodatabase.
            let featureTableNames = ["ParcelLines_1", "Loudoun_Address_Points_1"]
            let featureTables = featureTableNames.compactMap { self.geodatabase.geodatabaseFeatureTable(withName: $0) }
            let featureLayers = featureTables.map(AGSFeatureLayer.init)
            // Add the feature layers to the map.
            map.operationalLayers.addObjects(from: featureLayers)
            // Create annotation layers from tables in the geodatabase.
            let annotationTableNames = ["ParcelLinesAnno_1", "Loudoun_Address_PointsAnno_1"]
            let annotationTables = annotationTableNames.compactMap { self.geodatabase.geodatabaseAnnotationTable(withTableName: $0) }
            let annotationLayers = annotationTables.map(AGSAnnotationLayer.init)
            // Add the annotation layers to the map.
            map.operationalLayers.addObjects(from: annotationLayers)
        case .failure(let error):
            self.presentAlert(error: error)
        }
    }
    
    func selectFeature(at point: CGPoint) {
        // Clear any previously selected features.
        clearSelection()
        
        // Identify across all layers.
        identifyOperation = mapView.identifyLayers(atScreenPoint: point, tolerance: 10.0, returnPopupsOnly: false) { [weak self] (results: [AGSIdentifyLayerResult]?, error: Error?) in
            guard let self = self else { return }
            if let error = error {
                self.clearSelection()
                self.presentAlert(error: error)
            } else if let results = results {
                for result in results {
                    guard let featureLayer = result.layerContent as? AGSFeatureLayer, let selectedFeature = result.geoElements.first as? AGSFeature else { continue }
                    switch selectedFeature.geometry?.geometryType {
                    case .point:
                        // If the selected feature is a point, prompt the edit attributes alert.
                        self.showEditableAttributes(selectedFeature: selectedFeature)
                    case .polyline:
                        let polyline = selectedFeature.geometry as! AGSPolyline
                        // If the selected feature is a polyline with any part containing more than one segment (i.e. a curve), present an alert.
                        if polyline.parts.array().contains(where: { $0.pointCount > 2 }) {
                            self.presentAlert(title: "Make a different selection", message: "Select straight (single segment) polylines only.")
                            return
                        }
                    default:
                        return
                    }
                    // Select the feature.
                    featureLayer.select(selectedFeature)
                    // Set the feature globally.
                    self.selectedFeature = selectedFeature
                    return
                }
            }
        }
    }
    
    // Create an alert dialog with edit texts to allow editing of the given feature's 'AD_ADDRESS' and 'ST_STR_NAM' attributes.
    func showEditableAttributes(selectedFeature: AGSFeature) {
        // Create an object to observe changes from the text fields.
        var textFieldObserver: NSObjectProtocol!
        // Create an alert controller and customize the title and message.
        let alert = UIAlertController(title: "Edit Feature Attributes", message: "Edit the 'AD_ADDRESS' and 'ST_STR_NAM' attributes.", preferredStyle: .alert)
        // Add a "Done" option to complete the editing process and close the alert.
        let doneAction = UIAlertAction(title: "Done", style: .default) { _ in
            let addressTextField = alert.textFields?[0]
            let streetTextField = alert.textFields?[1]
            // Set the new values for the attributes and update the selected feature.
            selectedFeature.attributes["AD_ADDRESS"] = Int((addressTextField?.text)!)
            selectedFeature.attributes["ST_STR_NAM"] = streetTextField?.text
            selectedFeature.featureTable?.update(selectedFeature)
            // Remove the observer after editing is complete.
            if let textFieldObserver = textFieldObserver {
                NotificationCenter.default.removeObserver(textFieldObserver)
            }
        }
        alert.addAction(doneAction)
        // Add an observer to ensure the user does not input an empty string.
        textFieldObserver = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: nil, queue: .main, using: {_ in
            // Enable the done button if both textfields are not empty.
            doneAction.isEnabled = (alert.textFields?.allSatisfy { $0.text?.isEmpty == false })!
        })
        // Add a text field to prompt the user to input the street address.
        alert.addTextField { (textField) in
            // Prompt a number pad for the address.
            textField.keyboardType = .numberPad
            // Populate the text fields with the current value.
            textField.text = (selectedFeature.attributes["AD_ADDRESS"] as! NSNumber).stringValue
        }
        // Add a text field to prompt the user to input the street name.
        alert.addTextField { (textField) in
            // Prompt a keyboard to enter the street name.
            textField.keyboardType = .default
            textField.text = selectedFeature.attributes["ST_STR_NAM"] as? String
        }
        // Add a "Cancel" option and clear the selection if cancel is selected.
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.clearSelection()
            // Remove the observer after editing is complete.
            if let textFieldObserver = textFieldObserver {
                NotificationCenter.default.removeObserver(textFieldObserver)
            }
        })
        // Present the alert.
        present(alert, animated: true)
    }
    
    // Move the currently selected point feature to the given map point, by updating the selected feature's geometry and feature table.
    func moveSelectedFeature(to mapPoint: AGSPoint) {
        guard let selectedFeature = selectedFeature else { return }
        // Create an alert to confirm that the user wants to update the geometry.
        let alert = UIAlertController(title: "Confirm Update", message: "Are you sure you want to move the selected feature?", preferredStyle: .alert)
        // Clear the selection and selected feature if "No" is selected.
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.clearSelection()
        })
        alert.addAction(UIAlertAction(title: "Move", style: .default) { _ in
            // Set the selected feature's geometry to the new map point.
            selectedFeature.geometry = mapPoint
            // Update the selected feature's feature table.
            selectedFeature.featureTable?.update(selectedFeature) { [weak self] (error: Error?) in
                guard let self = self else { return }
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    // Clear selection of polyline.
                    self.clearSelection()
                }
            }
        })
        // Present the alert.
        present(alert, animated: true)
    }
    
    // Move the last of the vertex point of the currently selected polyline to the given map point, by updating the selected feature's geometry and feature table.
    func moveLastVertexOfSelectedFeature(to mapPoint: AGSPoint) {
        guard let selectedFeature = self.selectedFeature else { return }
        // Create an alert to confirm that the user wants to update the geometry.
        let alert = UIAlertController(title: "Confirm Update", message: "Are you sure you want to move the selected feature?", preferredStyle: .alert)
        // Clear the selection and selected feature if "No" is selected.
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.clearSelection()
        })
        alert.addAction(UIAlertAction(title: "Move", style: .default) { _ in
            // Get the selected feature's geometry as a polyline nearest to the map point.
            guard let polyline = selectedFeature.geometry as? AGSPolyline,
                let selectedMapPoint = AGSGeometryEngine.projectGeometry(mapPoint, to: polyline.spatialReference!) as? AGSPoint,
                let nearestVertex = AGSGeometryEngine.nearestVertex(in: polyline, to: selectedMapPoint) else { return }
            let polylineBuilder = AGSPolylineBuilder(polyline: polyline)
            // Get the part of the polyline nearest to the map point.
            polylineBuilder.parts[nearestVertex.partIndex].removePoint(at: nearestVertex.partIndex)
            // Add the map point as the new point on the polyline.
            polylineBuilder.parts[nearestVertex.partIndex].addPoint(AGSGeometryEngine.projectGeometry(mapPoint, to: polylineBuilder.parts[nearestVertex.partIndex].spatialReference!) as! AGSPoint)
            // Set the selected feature's geometry to the new polyline.
            selectedFeature.geometry = polylineBuilder.toGeometry()
            // Update the selected feature's feature table.
            selectedFeature.featureTable?.update(selectedFeature) { [weak self] (error: Error?) in
                guard let self = self else { return }
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    // Clear selection of polyline.
                    self.clearSelection()
                }
            }
        })
        present(alert, animated: true)
    }
    
    // Clear selection from all feature layers.
    func clearSelection() {
        selectedFeature = nil
        mapView.map?.operationalLayers.forEach { layer in
            if let featureLayer = layer as? AGSFeatureLayer {
                featureLayer.clearSelection()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditFeaturesWithFeatureLinkedAnnotationViewController"]
    }
}

// MARK: - AGSGeoViewTouchDelegate
// Select the nearest feature or move the point or polyline vertex to the given screen point.
extension EditFeaturesWithFeatureLinkedAnnotationViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let identifyOperation = identifyOperation {
            identifyOperation.cancel()
            self.identifyOperation = nil
        }
        // If a feature has been selected, determine what the type of geometry and move it accordingly.
        if let selectedFeature = selectedFeature {
            if selectedFeature.geometry?.geometryType == .polyline {
                moveLastVertexOfSelectedFeature(to: mapPoint)
            } else {
                moveSelectedFeature(to: mapPoint)
            }
        } else {
            // If a feature hasn't been selected.
            selectFeature(at: screenPoint)
        }
    }
}
