// Copyright 2015 Esri.
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

class EditGeometryViewController: UIViewController, AGSMapViewTouchDelegate, AGSCalloutDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var toolbar:UIToolbar!
    
    private var map:AGSMap!
    private var featureTable:AGSServiceFeatureTable!
    private var featureLayer:AGSFeatureLayer!
    private var sketchGraphicsOverlay:AGSSketchGraphicsOverlay!
    private var lastQuery:AGSCancellable!
    
    private var selectedFeature:AGSFeature!
    private let FEATURE_SERVICE_URL = "http://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0"
    
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
        
        self.sketchGraphicsOverlay = AGSSketchGraphicsOverlay(geometryBuilder: AGSPointBuilder(spatialReference: AGSSpatialReference.webMercator()))
        self.mapView.graphicsOverlays.addObject(self.sketchGraphicsOverlay)
        
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView, didTapAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        if let lastQuery = self.lastQuery{
            lastQuery.cancel()
        }
        
        //hide the callout
        self.mapView.callout.dismiss()
        
        let tolerance:Double = 22
        let mapTolerance = tolerance * self.mapView.unitsPerPixel
        let envelope = AGSEnvelope(XMin: mappoint.x - mapTolerance,
            yMin: mappoint.y - mapTolerance,
            xMax: mappoint.x + mapTolerance,
            yMax: mappoint.y + mapTolerance,
            spatialReference: self.map.spatialReference)
        
        let queryParams = AGSQueryParameters()
        queryParams.geometry = envelope
        queryParams.outFields = ["*"]
        
        self.lastQuery = self.featureTable.queryFeaturesWithParameters(queryParams, completion: { [weak self] (result:AGSFeatureQueryResult?, error:NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else if let feature = result?.nextObject() {
                //show callout for the first feature
                let title = feature.attributeValueForKey("typdamage") as! String
                self?.mapView.callout.title = title
                self?.mapView.callout.delegate = self
                self?.mapView.callout.showCalloutForFeature(feature, layer: self!.featureLayer, tapLocation: mappoint, animated: true)
                //update selected feature
                self?.selectedFeature = feature
            }
        })
    }
    
    //MARK: - AGSCalloutDelegate
    
    func didTapAccessoryButtonForCallout(callout: AGSCallout) {
        //hide the callout
        self.mapView.callout.dismiss()
        
        //add the default geometry
        self.sketchGraphicsOverlay.addPart()
        let point = self.selectedFeature.geometry as! AGSPoint
        self.sketchGraphicsOverlay.insertVertex(point, inPart: 0, atIndex: 0)
        
        //assign sketch graphics overlay as the touch delegate
        self.mapView.touchDelegate = self.sketchGraphicsOverlay
        
        //show the toolbar
        self.toolbar.hidden = false
        
        //hide the feature for time being
        self.featureLayer.setFeature(self.selectedFeature, visible: false)
    }
    
    //MARK: - Actions
    
    @IBAction func doneAction() {
        if let newGeometry = self.sketchGraphicsOverlay.geometry {
            self.selectedFeature.geometry = newGeometry
            self.featureTable.updateFeature(self.selectedFeature, completion: { [weak self] (error:NSError?) -> Void in
                if let error = error {
                    print(error)
                    
                    //un hide the feature
                    self?.featureLayer.setFeature(self!.selectedFeature, visible: true)
                }
                else {
                    self?.featureTable.applyEditsWithCompletion({ (result:[AGSFeatureEditResult]?, error:NSError?) -> Void in
                        if let error = error {
                            print(error)
                        }
                        else {
                            SVProgressHUD.showSuccessWithStatus("Saved successfully!")
                        }
                        //un hide the feature
                        self?.featureLayer.setFeature(self!.selectedFeature, visible: true)
                    })
                }
            })
        }
        //hide toolbar
        self.toolbar.hidden = true
        //assign self as the touch delegate
        self.mapView.touchDelegate = self
        //clear sketch graphics overlay
        self.sketchGraphicsOverlay.clear()
    }
}
