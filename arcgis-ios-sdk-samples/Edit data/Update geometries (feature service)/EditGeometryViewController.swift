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
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var toolbar:UIToolbar!
    @IBOutlet private var toolbarBottomConstraint:NSLayoutConstraint!
    
    private var map:AGSMap!
    private var featureTable:AGSServiceFeatureTable!
    private var featureLayer:AGSFeatureLayer!
    private var lastQuery:AGSCancelable!
    
    private var selectedFeature:AGSArcGISFeature!
    private let FEATURE_SERVICE_URL = "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditGeometryViewController"]
        
        self.map = AGSMap(basemap: AGSBasemap.oceans())
        //set initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -9030446.96, y: 943791.32, spatialReference: AGSSpatialReference.webMercator()), scale: 2e6)
        
        self.featureTable = AGSServiceFeatureTable(url: URL(string: FEATURE_SERVICE_URL)!)
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        
        self.map.operationalLayers.add(self.featureLayer)

        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //default state for toolbar is off
        self.toggleToolbar(false)
    }
    
    func toggleToolbar(_ on:Bool) {
        
        if #available(iOS 11.0, *) {
            self.toolbarBottomConstraint.constant = on ? 0 : -44-view.safeAreaInsets.bottom
            print(view.safeAreaInsets.bottom)
        }
        else {
            self.toolbarBottomConstraint.constant = on ? 0 : -44
        }
        
        UIView.animate(withDuration: 0.3, animations: { [weak self] () -> Void in
            self?.view.layoutIfNeeded()
        }) 
    }
    
    func applyEdits() {
        self.featureTable.applyEdits(completion: { [weak self] (result:[AGSFeatureEditResult]?, error:Error?) -> Void in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
            }
            else {
                SVProgressHUD.showSuccess(withStatus: "Saved successfully!")
            }
            //un hide the feature
            self?.featureLayer.setFeature(self!.selectedFeature, visible: true)
        })
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let lastQuery = self.lastQuery{
            lastQuery.cancel()
        }
        
        //hide the callout
        self.mapView.callout.dismiss()
        
        self.lastQuery = self.mapView.identifyLayer(self.featureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 1) { [weak self] (identifyLayerResult: AGSIdentifyLayerResult) -> Void in
            if let error = identifyLayerResult.error {
                print(error)
            }
            else if let features = identifyLayerResult.geoElements as? [AGSArcGISFeature] , features.count > 0 {
                let feature = features[0]
                //show callout for the first feature
                let title = feature.attributes["typdamage"] as! String
                self?.mapView.callout.title = title
                self?.mapView.callout.delegate = self
                self?.mapView.callout.show(for: feature, tapLocation: mapPoint, animated: true)
                //update selected feature
                self?.selectedFeature = feature
            }
        }
    }
    
    //MARK: - AGSCalloutDelegate
    
    func didTapAccessoryButton(for callout: AGSCallout) {
        //hide the callout
        self.mapView.callout.dismiss()
        
        //add the default geometry
        let point = self.selectedFeature.geometry as! AGSPoint
        
        //instantiate sketch editor with selected feature's geometry
        self.mapView.sketchEditor = AGSSketchEditor()
        
        //enable the sketch editor to start tracking user gesture
        self.mapView.sketchEditor?.start(with: point)
        
        //show the toolbar
        self.toggleToolbar(true)
        
        //hide the feature for time being
        self.featureLayer.setFeature(self.selectedFeature, visible: false)
    }
    
    //MARK: - Actions
    
    @IBAction func doneAction() {
        if let newGeometry = self.mapView.sketchEditor?.geometry {

            self.selectedFeature.geometry = newGeometry
            self.featureTable.update(self.selectedFeature, completion: { [weak self] (error:Error?) -> Void in
                if let error = error {
                    SVProgressHUD.showError(withStatus: error.localizedDescription)
                    
                    //un hide the feature
                    self?.featureLayer.setFeature(self!.selectedFeature, visible: true)
                }
                else {
                    //apply edits
                    self?.applyEdits()
                }
            })
        }
        
        //hide toolbar
        self.toggleToolbar(false)
        
        //disable sketch editor
        self.mapView.sketchEditor?.stop()
        
        //clear sketch editor
        self.mapView.sketchEditor?.clearGeometry()
    }
}
