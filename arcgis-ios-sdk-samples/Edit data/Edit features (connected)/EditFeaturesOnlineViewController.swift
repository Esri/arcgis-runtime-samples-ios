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

class EditFeaturesOnlineViewController: UIViewController, AGSGeoViewTouchDelegate, AGSPopupsViewControllerDelegate, FeatureTemplatePickerDelegate {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            // Set touch delegate on map view as self.
            mapView.touchDelegate = self
            // Assign the sketch editor to map view.
            mapView.sketchEditor = sketchEditor
        }
    }
    @IBOutlet var sketchToolbar: UIToolbar!
    @IBOutlet var doneBarButtonItem: UIBarButtonItem!
    
    /// The service geodatabase that contains damaged property features.
    var serviceGeodatabase: AGSServiceGeodatabase!
    /// The feature layer created from the service geodatabase.
    var featureLayer: AGSFeatureLayer!
    /// The feature table to edit features.
    var featureTable: AGSServiceFeatureTable!
    /// The sketch editor on the map view for editing the feature.
    var sketchEditor = AGSSketchEditor()
    /// The popup view controller to view and edit feature attributes.
    var popupsViewController: AGSPopupsViewController!
    /// Last identify operation.
    var lastQuery: AGSCancelable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["EditFeaturesOnlineViewController", "FeatureTemplatePickerViewController"]
        // Hide the sketchToolbar initially.
        sketchToolbar.isHidden = true
        // Load the service geodatabase.
        let damageFeatureService = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer")!
        loadServiceGeodatabase(from: damageFeatureService)
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
                // Store the feature layer for later use.
                self.featureLayer = featureLayer
                self.mapView.map?.operationalLayers.add(featureLayer)
                self.mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -9184518.55, y: 3240636.90, spatialReference: .webMercator()), scale: 7e5))
            }
        }
    }
    
    private func dismissFeatureTemplatePickerViewController() {
        self.dismiss(animated: true)
    }
    
    /// Apply local edits to the geodatabase.
    func applyEdits() {
        if serviceGeodatabase.hasLocalEdits() {
            serviceGeodatabase.applyEdits { [weak self] featureTableEditResults, error in
                guard let self = self else { return }
                if let featureTableEditResults = featureTableEditResults,
                   featureTableEditResults.first?.editResults.first?.completedWithErrors == false {
                    self.presentAlert(message: "Edits applied successfully!")
                } else if let error = error {
                    self.presentAlert(message: "Error while applying edits: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let lastQuery = self.lastQuery {
            lastQuery.cancel()
        }
        
        self.lastQuery = self.mapView.identifyLayer(self.featureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 10) { [weak self] (identifyLayerResult: AGSIdentifyLayerResult) in
            guard let self = self else { return }
            if let error = identifyLayerResult.error {
                print(error)
            } else if !identifyLayerResult.geoElements.isEmpty {
                let popups = identifyLayerResult.geoElements.map(AGSPopup.init(geoElement:))
                self.popupsViewController = AGSPopupsViewController(popups: popups, containerStyle: .navigationBar)
                self.popupsViewController.modalPresentationStyle = .formSheet
                self.popupsViewController.isModalInPresentation = true
                self.present(self.popupsViewController, animated: true)
                self.popupsViewController.delegate = self
            }
        }
    }
    
    // MARK: - AGSPopupsViewControllerDelegate methods
    
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, sketchEditorFor popup: AGSPopup) -> AGSSketchEditor? {
        if let geometry = popup.geoElement.geometry {
            // Start sketch editing.
            self.mapView.sketchEditor?.start(with: geometry)
            
            // Zoom to the existing feature's geometry.
            self.mapView.setViewpointGeometry(geometry.extent, padding: 10, completion: nil)
        }
        
        return self.sketchEditor
    }
    
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, readyToEditGeometryWith sketchEditor: AGSSketchEditor?, for popup: AGSPopup) {
        // Dismiss the popup view controller.
        self.dismiss(animated: true)
        
        // Prepare the current view controller for sketch mode.
        self.mapView.callout.isHidden = true
        
        // Hide the back button.
        self.navigationItem.hidesBackButton = true
        
        // Disable the code button.
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        // Unhide the sketchToolbar.
        self.sketchToolbar.isHidden = false
        
        // Disable the done button until any geometry changes.
        self.doneBarButtonItem.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(EditFeaturesOnlineViewController.sketchChanged(_:)), name: .AGSSketchEditorGeometryDidChange, object: nil)
    }
    
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, didCancelEditingFor popup: AGSPopup) {
        // Stop sketch editor.
        self.disableSketchEditor()
    }
    
    func popupsViewController(_ popupsViewController: AGSPopupsViewController, didFinishEditingFor popup: AGSPopup) {
        // Stop sketch editor.
        self.disableSketchEditor()
        
        let feature = popup.geoElement as! AGSFeature
        
        // Simplify the geometry, which will take care of self intersecting
        // polygons and normalize the geometry, which will take care of
        // geometries that extend beyone the dateline (if wraparound was enabled
        // on the map)
        feature.geometry = AGSGeometryEngine.simplifyGeometry(feature.geometry!)
        feature.geometry = AGSGeometryEngine.normalizeCentralMeridian(of: feature.geometry!)
        
        // Apply edits.
        self.applyEdits()
    }
    
    func popupsViewControllerDidFinishViewingPopups(_ popupsViewController: AGSPopupsViewController) {
        // Dismiss the popups view controller.
        self.dismiss(animated: true)
        
        self.popupsViewController = nil
    }
    
    @objc
    func sketchChanged(_ notification: Notification) {
        // Check if the sketch geometry is valid to decide whether to enable
        // the sketchCompleteButton.
        if let geometry = self.mapView.sketchEditor?.geometry, !geometry.isEmpty {
            self.doneBarButtonItem.isEnabled = true
        }
    }
    
    @IBAction func sketchDoneAction() {
        // Enable or unhide navigation bar button.
        self.navigationItem.hidesBackButton = false
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        
        // Present the popups view controller again.
        self.present(self.popupsViewController, animated: true)
        
        // Remove self as observer for notifications.
        NotificationCenter.default.removeObserver(self, name: .AGSSketchEditorGeometryDidChange, object: nil)
    }
    
    private func disableSketchEditor() {
        // Stop sketch editor.
        self.mapView.sketchEditor?.stop()
        
        // Hide sketch toolbar.
        self.sketchToolbar.isHidden = true
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FeatureTemplateSegue",
           let navigationController = segue.destination as? UINavigationController,
           let featureTemplatePickerViewController = navigationController.topViewController as? FeatureTemplatePickerViewController {
            featureTemplatePickerViewController.addTemplatesFromLayer(featureLayer)
            featureTemplatePickerViewController.delegate = self
        }
    }
    
    // MARK: - FeatureTemplatePickerDelegate
    
    func featureTemplatePickerViewController(_ controller: FeatureTemplatePickerViewController, didSelectFeatureTemplate template: AGSFeatureTemplate, forFeatureLayer featureLayer: AGSFeatureLayer) {
        // Create a new feature based on the template.
        let newFeature = featureTable.createFeature(with: template)!
        
        // Set the geometry as the center of the screen.
        if let visibleArea = self.mapView.visibleArea {
            newFeature.geometry = visibleArea.extent.center
        } else {
            newFeature.geometry = AGSPoint(x: 0, y: 0, spatialReference: .webMercator())
        }
        
        // Initialize a popup definition using the feature layer.
        let popupDefinition = AGSPopupDefinition(popupSource: self.featureLayer)
        // Create a popup.
        let popup = AGSPopup(geoElement: newFeature, popupDefinition: popupDefinition)
        
        // Initialize popups view controller.
        self.popupsViewController = AGSPopupsViewController(popups: [popup], containerStyle: .navigationBar)
        self.popupsViewController.delegate = self
        
        // Only for iPad, set presentation style to Form sheet.
        // We don't want it to cover the entire screen.
        self.popupsViewController.modalPresentationStyle = .formSheet
        self.popupsViewController.isModalInPresentation = true
        
        // First, dismiss the Feature Template Picker.
        self.dismiss(animated: false)
        
        // Next, Present the popup view controller.
        self.present(self.popupsViewController, animated: true) { [weak self] in
            self?.popupsViewController.startEditingCurrentPopup()
        }
    }
    
    func featureTemplatePickerViewControllerWantsToDismiss(_ controller: FeatureTemplatePickerViewController) {
        self.dismissFeatureTemplatePickerViewController()
    }
}
