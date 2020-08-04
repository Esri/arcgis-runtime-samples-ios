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

class EditFeaturesWithFeatureLinkedAnnotationViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            // Create the map with a light gray canvas basemap centered on Loudoun, Virginia.
            let map = AGSMap(basemapType: .lightGrayCanvasVector, latitude: 39.0204, longitude: -77.4159, levelOfDetail: 18)
            mapView.map = map
            loadGeodatabase()
        }
    }
    private var selectedFeature: AGSFeature?
    private var selectedFeatureIsPolyline = false
    
    func loadGeodatabase() {
        // Load geodatabase from shared resources.
        let geodatabaseURL = Bundle.main.url(forResource: "loudoun_anno", withExtension: ".geodatabase")!
        let geodatabase = AGSGeodatabase(fileURL: geodatabaseURL)
//        let group = DispatchGroup()
//        group.enter()
        geodatabase.load { (error: Error?) in
//            guard let map = self.mapView.map else { return }
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
//                group.leave()
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
        
        // Identify across all layers
        mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 10.0, returnPopupsOnly: false) { (results: [AGSIdentifyLayerResult]?, error: Error?) in
//        guard let selectedFeature = self.selectedFeature else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                results?.forEach { (result) in
                    if let featureLayer = result.layerContent as? AGSFeatureLayer {
                        // Get a reference to the identified feature
                        self.selectedFeature = result.geoElements[0] as? AGSFeature
                        // If the selected feature is a polyline with any part containing more than one segment (i.e. a curve).
                        if let polyline = self.selectedFeature?.geometry as? AGSPolyline {
                            let polylineArray = polyline.parts.array()
                            polylineArray.forEach { part in
                                if part.pointCount > 2 {
                                    // Set selected feature to nil.
                                    self.selectedFeature = nil
                                    // Show a message to select straight (single segment) polylines only.
                                    self.presentAlert(title: "Make a different selection", message: "Select straight (single segment) polylines only.")
                                    return
                                }
                            }
                        }
                        featureLayer.select(self.selectedFeature!)
                        if self.selectedFeature?.geometry?.geometryType.rawValue == 1 {
                            self.showEditableAttributes(selectedFeature: self.selectedFeature!)
                        } else if self.selectedFeature?.geometry?.geometryType.rawValue == 3 {
                            self.selectedFeatureIsPolyline = true
                        }
                    }
                }
            }
        }
    }
    
    // Create an alert dialog with edit texts to allow editing of the given feature's 'AD_ADDRESS' and 'ST_STR_NAM' attributes.
    func showEditableAttributes(selectedFeature: AGSFeature) {
        // Inflate the edit attribute layout.
        let alert = UIAlertController(title: "Edit feature attributes", message: "Edit the 'AD_ADDRESS' and 'ST_STR_NAM' attributes.", preferredStyle: .alert)
        alert.addTextField()
        alert.textFields?[0].text = (selectedFeature.attributes["AD_ADDRESS"] as! NSNumber).stringValue
        alert.textFields?[1].text = selectedFeature.attributes["ST_STR_NAM"] as? String
        alert.textFields?[0].keyboardType = .asciiCapableNumberPad
        alert.textFields?[1].keyboardType = .asciiCapable
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Done", style: .default) { _ in
            let addressTextField = alert.textFields?[0]
            let streetTextField = alert.textFields?[1]
            selectedFeature.attributes["AD_ADDRESS"] = addressTextField?.text
            selectedFeature.attributes["ST_STR_NAM"] = streetTextField?.text
            selectedFeature.featureTable?.update(selectedFeature)
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    // Move the currently selected point feature to the given map point, by updating the selected feature's geometry and feature table.
    func movePoint(mapPoint: AGSPoint) {
//        guard let selectedFeature = self.selectedFeature else { return }
        let alert = UIAlertController(title: "Confirm update", message: "Would you like to update the geometry?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
        alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            // Set the selected feature's geometry to the new map point.
            self.selectedFeature?.geometry = mapPoint
            // Update the selected feature's feature table.
            self.selectedFeature?.featureTable?.update(self.selectedFeature!) { (error: Error?) in
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    // Clear selection of polyline.
                    self.clearSelection()
                    self.selectedFeature = nil
                }
            }
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    // Move the last of the vertex point of the currently selected polyline to the given map point, by updating the selected feature's geometry and feature table.
    func movePolylineVertex(mapPoint: AGSPoint) {
        let alert = UIAlertController(title: "Confirm update", message: "Would you like to update the geometry?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel))
            alert.addAction(UIAlertAction(title: "Yes", style: .default) { _ in
            // Get the selected feature's geometry as a polyline nearest to the map point.
            let polyline = selectedFeature?.geometry as? AGSPolyline
            // Get the nearest vertex to the map point on the selected feature polyline.
            let nearestVertex = AGSGeometryEngine.nearestVertex(in: polyline!, to: (AGSGeometryEngine.projectGeometry(mapPoint, to: (polyline?.spatialReference)!) as? AGSPoint)!)
            let polylineBuilder = AGSPolylineBuilder(polyline: polyline)
            // Get the part of the polyline nearest to the map point.
            polylineBuilder.parts[nearestVertex!.partIndex].removePoint(at: nearestVertex!.partIndex)
            // Add the map point as the new point on the polyline.
            polylineBuilder.parts[nearestVertex!.partIndex].addPoint(AGSGeometryEngine.projectGeometry(mapPoint, to: polylineBuilder.parts[nearestVertex!.partIndex].spatialReference!) as! AGSPoint)
            // Set the selected feature's geometry to the new polyline.
            selectedFeature?.geometry = polylineBuilder.toGeometry()
            // Update the selected feature's feature table.
            selectedFeature?.featureTable?.update(selectedFeature!) { (error: Error?) in
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
        self.mapView.map?.operationalLayers.forEach { (each) in
            if let featureLayer = each as? AGSFeatureLayer {
                featureLayer.clearSelection()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the touch delegate.
        self.mapView.touchDelegate = self
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditFeaturesWithFeatureLinkedAnnotationViewController"]
    }
}
