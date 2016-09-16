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
    private var geometrySketchEditor:AGSGeometrySketchEditor!
    private var lastQuery:AGSCancellable!
    
    private var selectedFeature:AGSArcGISFeature!
    private let FEATURE_SERVICE_URL = "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditGeometryViewController"]
        
        self.map = AGSMap(basemap: AGSBasemap.oceansBasemap())
        //set initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -9030446.96, y: 943791.32, spatialReference: AGSSpatialReference.webMercator()), scale: 2e6)
        
        self.featureTable = AGSServiceFeatureTable(URL: NSURL(string: FEATURE_SERVICE_URL)!)
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        
        self.map.operationalLayers.addObject(self.featureLayer)
        
        self.geometrySketchEditor = AGSGeometrySketchEditor(geometryBuilder: AGSPointBuilder(spatialReference: AGSSpatialReference.webMercator()))
        self.mapView.sketchEditor =  self.geometrySketchEditor

        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
        //default state for toolbar is off
        self.toggleToolbar(false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func toggleToolbar(on:Bool) {
        self.toolbarBottomConstraint.constant = on ? 0 : -44
        UIView.animateWithDuration(0.3) { [weak self] () -> Void in
            self?.view.layoutIfNeeded()
        }
    }
    
    func applyEdits() {
        self.featureTable.applyEditsWithCompletion({ [weak self] (result:[AGSFeatureEditResult]?, error:NSError?) -> Void in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription)
            }
            else {
                SVProgressHUD.showSuccessWithStatus("Saved successfully!")
            }
            //un hide the feature
            self?.featureLayer.setFeature(self!.selectedFeature, visible: true)
        })
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let lastQuery = self.lastQuery{
            lastQuery.cancel()
        }
        
        //hide the callout
        self.mapView.callout.dismiss()
        
        self.lastQuery = self.mapView.identifyLayer(self.featureLayer, screenPoint: screenPoint, tolerance: 5, maximumResults: 1) { [weak self] (identifyLayerResult: AGSIdentifyLayerResult?, error: NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else if let features = identifyLayerResult?.geoElements as? [AGSArcGISFeature] where features.count > 0 {
                let feature = features[0]
                //show callout for the first feature
                let title = feature.attributes["typdamage"] as! String
                self?.mapView.callout.title = title
                self?.mapView.callout.delegate = self
                self?.mapView.callout.showCalloutForFeature(feature, tapLocation: mapPoint, animated: true)
                //update selected feature
                self?.selectedFeature = feature
            }
        }
    }
    
    //MARK: - AGSCalloutDelegate
    
    func didTapAccessoryButtonForCallout(callout: AGSCallout) {
        //hide the callout
        self.mapView.callout.dismiss()
        
        //add the default geometry
        self.geometrySketchEditor.addPart()
        let point = self.selectedFeature.geometry as! AGSPoint
        self.geometrySketchEditor.insertVertex(point, inPart: 0, atIndex: 0)
        
        //enable the sketch editor to start tracking user gesture
        self.geometrySketchEditor.enabled = true
        
        //show the toolbar
//        self.toolbar.hidden = false
        self.toggleToolbar(true)
        
        //hide the feature for time being
        self.featureLayer.setFeature(self.selectedFeature, visible: false)
    }
    
    //MARK: - Actions
    
    @IBAction func doneAction() {
        if let newGeometry = self.geometrySketchEditor.geometry {

            self.selectedFeature.geometry = newGeometry
            self.featureTable.updateFeature(self.selectedFeature, completion: { [weak self] (error:NSError?) -> Void in
                if let error = error {
                    SVProgressHUD.showErrorWithStatus(error.localizedDescription)
                    
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
//        self.toolbar.hidden = true
        self.toggleToolbar(false)
        
        //disable sketch editor
        self.geometrySketchEditor.enabled = false
        
        //clear sketch editor
        self.geometrySketchEditor.clear()
        
        
    }
}
