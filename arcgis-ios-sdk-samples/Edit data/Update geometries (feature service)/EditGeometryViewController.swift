// Copyright 2016 Esri.
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

class EditGeometryViewController: UIViewController, AGSGeoViewTouchDelegate, AGSCalloutDelegate {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISOceans)
            mapView.sketchEditor = sketchEditor
            // Set touch delegate on map view as self.
            mapView.touchDelegate = self
            mapView.callout.delegate = self
        }
    }
    
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var toolbarBottomConstraint: NSLayoutConstraint!
    
    /// The feature table to update features geometries.
    var featureTable: AGSServiceFeatureTable!
    /// The service geodatabase that contains damaged property features.
    var serviceGeodatabase: AGSServiceGeodatabase!
    /// The feature layer created from the feature table.
    var featureLayer: AGSFeatureLayer!
    /// Last identify operation.
    var lastQuery: AGSCancelable!
    /// The currently selected feature.
    var selectedFeature: AGSFeature!
    /// The sketch editor on the map view.
    let sketchEditor = AGSSketchEditor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["EditGeometryViewController"]
        
        // Load the service geodatabase.
        let damageFeatureService = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer")!
        loadServiceGeodatabase(from: damageFeatureService)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Default state for toolbar is hidden.
        setToolbarVisibility(visible: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if sketchEditor.isStarted, let feature = selectedFeature {
            // Make the feature visible when sketch editor is started.
            featureLayer.setFeature(feature, visible: true)
            // Stop sketch editor.
            sketchEditor.stop()
        }
        setToolbarVisibility(visible: false)
    }
    
    /// Load and set a service geodatabase from a feature service URL.
    /// - Parameter serviceURL: The URL to the feature service.
    func loadServiceGeodatabase(from serviceURL: URL) {
        let serviceGeodatabase = AGSServiceGeodatabase(url: serviceURL)
        serviceGeodatabase.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                let featureTable = serviceGeodatabase.table(withLayerID: 0)!
                self.featureTable = featureTable
                self.serviceGeodatabase = serviceGeodatabase
                // Add the feature layer to the operational layers on map.
                let featureLayer = AGSFeatureLayer(featureTable: featureTable)
                self.featureLayer = featureLayer
                self.mapView.map?.operationalLayers.add(featureLayer)
                self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -9030446.96, y: 943791.32, spatialReference: .webMercator()), scale: 2e6))
            }
        }
    }
    
    func setToolbarVisibility(visible: Bool) {
        toolbarBottomConstraint.constant = visible ? 0 : -toolbar.frame.height - view.safeAreaInsets.bottom
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    /// Apply local edits to the geodatabase.
    func applyEdits() {
        guard serviceGeodatabase.hasLocalEdits() else { return }
        serviceGeodatabase.applyEdits { [weak self] (featureTableEditResults: [AGSFeatureTableEditResult]?, error: Error?) in
            guard let self = self else { return }
            if let featureTableEditResults = featureTableEditResults,
               featureTableEditResults.first?.editResults.first?.completedWithErrors == false {
                self.featureLayer.setFeature(self.selectedFeature, visible: true)
            } else if let error = error {
                self.presentAlert(message: "Error while applying edits: \(error.localizedDescription)")
            }
        }
    }
    
    func showCallout(for feature: AGSFeature, at tapLocation: AGSPoint?) {
        let title = feature.attributes["typdamage"] as! String
        mapView.callout.title = title
        mapView.callout.show(for: feature, tapLocation: tapLocation, animated: true)
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let query = lastQuery { query.cancel() }
        // Hide the callout.
        mapView.callout.dismiss()
        
        lastQuery = mapView.identifyLayer(featureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] identifyLayerResult in
            guard let self = self else { return }
            self.lastQuery = nil
            if let feature = identifyLayerResult.geoElements.first as? AGSFeature {
                // Show callout for the feature.
                self.showCallout(for: feature, at: mapPoint)
                // Update selected feature.
                self.selectedFeature = feature
            } else if let error = identifyLayerResult.error {
                self.presentAlert(error: error)
            }
        }
    }
    
    // MARK: - AGSCalloutDelegate
    
    func didTapAccessoryButton(for callout: AGSCallout) {
        guard let point = selectedFeature.geometry as? AGSPoint else { return }
        // Hide the callout.
        mapView.callout.dismiss()
        
        // Start the sketch editor with selected feature's geometry to start
        // tracking user gesture.
        sketchEditor.start(with: point)
        
        // Show the toolbar.
        setToolbarVisibility(visible: true)
        // Hide the feature for time being.
        featureLayer.setFeature(selectedFeature, visible: false)
    }
    
    // MARK: - Actions
    
    @IBAction func doneAction() {
        if let newGeometry = sketchEditor.geometry {
            selectedFeature.geometry = newGeometry
            featureTable.update(selectedFeature) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    self.presentAlert(error: error)
                    // Make the feature visible due to unsuccessful update.
                    self.featureLayer.setFeature(self.selectedFeature, visible: true)
                } else {
                    // Apply edits.
                    self.applyEdits()
                }
            }
        }
        // Hide toolbar.
        setToolbarVisibility(visible: false)
        // Stop and clear sketch editor.
        sketchEditor.stop()
    }
}
