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

class EditFeaturesWithFeatureLinkedAnnotationViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            // Create the map with a light gray canvas basemap centered on Loudoun, Virginia.
            mapView.map = AGSMap(basemapType: .lightGrayCanvasVector, latitude: 39.0204, longitude: -77.4159, levelOfDetail: 18)
            // Set the touch delegate.
            mapView.touchDelegate = self
            loadGeodatabase()
        }
    }
    private var selectedFeature: AGSFeature?
    private var selectedFeatureIsPolyline = false
    
    func loadGeodatabase() {
        // Load geodatabase from shared resources.
        let geodatabaseURL = Bundle.main.url(forResource: "loudoun_anno", withExtension: ".geodatabase")!
        let geodatabase = AGSGeodatabase(fileURL: geodatabaseURL)
        geodatabase.load { (error: Error?) in
            if let error = error {
                self.presentAlert(error: error)
            } else {
                guard let map = self.mapView.map else { return }
                // Create feature layers from tables in the geodatabase.
                let parcelLinesFeatureLayer = AGSFeatureLayer(featureTable: geodatabase.geodatabaseFeatureTable(withName: "ParcelLines_1")!)
                let addressPointFeatureLayer = AGSFeatureLayer(featureTable: geodatabase.geodatabaseFeatureTable(withName: "Loudoun_Address_Points_1")!)
                // Create annotation layers from tables in the geodatabase.
                let parcelLinesAnnotationLayer = AGSAnnotationLayer(featureTable: geodatabase.geodatabaseAnnotationTable(withTableName: "ParcelLinesAnno_1")!)
                let addressPointsAnnotationLayer = AGSAnnotationLayer(featureTable: geodatabase.geodatabaseAnnotationTable(withTableName: "Loudoun_Address_PointsAnno_1")!)
                // Add the feature layers to the map.
                map.operationalLayers.add(parcelLinesFeatureLayer)
                map.operationalLayers.add(addressPointFeatureLayer)
                // Add the annotation layers to the map.
                map.operationalLayers.add(parcelLinesAnnotationLayer)
                map.operationalLayers.add(addressPointsAnnotationLayer)
            }
        }
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    // Select the nearest feature or move the point or polyline vertex to the given screen point.
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // If a feature hasn't been selected.
        if selectedFeature == nil {
            selectFeature(screenPoint: screenPoint)
        } else {
            // Move the feature.
            if selectedFeatureIsPolyline {
                movePolylineVertex(mapPoint: mapPoint)
            } else {
                movePoint(mapPoint: mapPoint)
            }
        }
    }
    
    func selectFeature(screenPoint: CGPoint) {
        // Clear any previously selected features.
        clearSelection()
        selectedFeature = nil
        
        // Identify across all layers.
        mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 10.0, returnPopupsOnly: false) { (results: [AGSIdentifyLayerResult]?, error: Error?) in
            if let error = error {
                self.presentAlert(error: error)
                return
            }
            results?.forEach { (result) in
                //Get a reference to the identified feature layer and feature.
                guard let featureLayer = result.layerContent as? AGSFeatureLayer, let selectedFeature = result.geoElements[0] as? AGSFeature else { return }
                switch selectedFeature.geometry?.geometryType {
                case .point:
                    // If the selected feature is a point, prompt the edit attributes alert.
                    self.showEditableAttributes(selectedFeature: selectedFeature)
                case .polyline:
                    let polyline = selectedFeature.geometry as! AGSPolyline
                    let polylineArray = polyline.parts.array()
                    // If the selected feature is a polyline with any part containing more than one segment (i.e. a curve), present an alert.
                    for part in polylineArray {
                        if part.pointCount > 2 {
                            // Set the value to nil.
                            self.selectedFeature = nil
                            // Present the alert.
                            self.presentAlert(title: "Make a different selection", message: "Select straight (single segment) polylines only.")
                            return
                        }
                    }
                    // If the selected feature is a valid polyline, set the value to true.
                    self.selectedFeatureIsPolyline = true
                default:
                    return
                }
                // Select the feature.
                featureLayer.select(selectedFeature)
                // Set the feature globally.
                self.selectedFeature = selectedFeature
            }
        }
    }
    
    // Create an alert dialog with edit texts to allow editing of the given feature's 'AD_ADDRESS' and 'ST_STR_NAM' attributes.
    func showEditableAttributes(selectedFeature: AGSFeature) {
        // Create an alert controller and customize the title and message.
        let alert = UIAlertController(title: "Edit feature attributes", message: "Edit the 'AD_ADDRESS' and 'ST_STR_NAM' attributes.", preferredStyle: .alert)
        // Add text fields to prompt user input.
        alert.addTextField()
        alert.addTextField()
        // Populate the text fields with the current values.
        alert.textFields?[0].text = (selectedFeature.attributes["AD_ADDRESS"] as! NSNumber).stringValue
        alert.textFields?[1].text = selectedFeature.attributes["ST_STR_NAM"] as? String
        // Prompt the appropriate keyboard types.
        alert.textFields?[0].keyboardType = .numberPad
        alert.textFields?[1].keyboardType = .default
        // Add a "Cancel" option and clear the selection if cancel is selected.
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.clearSelection()
            self.selectedFeature = nil
        })
        // Add a "Done" option to complete the editing process and close the alert.
        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            let addressTextField = alert.textFields?[0]
            let streetTextField = alert.textFields?[1]
            // Set the new values for the attributes and update the selected feature.
            selectedFeature.attributes["AD_ADDRESS"] = Int((addressTextField?.text)!)
            selectedFeature.attributes["ST_STR_NAM"] = streetTextField?.text
            selectedFeature.featureTable?.update(selectedFeature)
        })
        // Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    // Move the currently selected point feature to the given map point, by updating the selected feature's geometry and feature table.
    func movePoint(mapPoint: AGSPoint) {
        guard let selectedFeature = self.selectedFeature else { return }
        // Create an alert to confirm that the user wants to update the geometry.
        let alert = UIAlertController(title: "Confirm update", message: "Would you like to update the geometry?", preferredStyle: .alert)
        // Clear the selection and selected feature if "No" is selected.
        alert.addAction(UIAlertAction(title: "No", style: .cancel) { _ in
            self.clearSelection()
            self.selectedFeature = nil
        })
        alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            // Set the selected feature's geometry to the new map point.
            selectedFeature.geometry = mapPoint
            // Update the selected feature's feature table.
            selectedFeature.featureTable?.update(selectedFeature) { (error: Error?) in
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    // Clear selection of polyline.
                    self.clearSelection()
                    self.selectedFeature = nil
                }
            }
        })
        // Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    // Move the last of the vertex point of the currently selected polyline to the given map point, by updating the selected feature's geometry and feature table.
    func movePolylineVertex(mapPoint: AGSPoint) {
        guard let selectedFeature = self.selectedFeature else { return }
        // Create an alert to confirm that the user wants to update the geometry.
        let alert = UIAlertController(title: "Confirm update", message: "Would you like to update the geometry?", preferredStyle: .alert)
        // Clear the selection and selected feature if "No" is selected.
        alert.addAction(UIAlertAction(title: "No", style: .cancel) { _ in
            self.clearSelection()
            self.selectedFeatureIsPolyline = false
            self.selectedFeature = nil
        })
        alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
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
            selectedFeature.featureTable?.update(selectedFeature) { (error: Error?) in
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    // Clear selection of polyline.
                    self.clearSelection()
                    self.selectedFeatureIsPolyline = false
                    self.selectedFeature = nil
                }
            }
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    // Clear selection from all feature layers.
    func clearSelection() {
        self.mapView.map?.operationalLayers.forEach { layer in
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
