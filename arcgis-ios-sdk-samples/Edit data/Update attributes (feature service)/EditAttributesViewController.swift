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

class EditAttributesViewController: UIViewController, AGSMapViewTouchDelegate, AGSCalloutDelegate, EAOptionsVCDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var featureTable:AGSServiceFeatureTable!
    private var featureLayer:AGSFeatureLayer!
    private var lastQuery:AGSCancellable!
    
    private var types = ["Destroyed", "Major", "Minor", "Affected", "Inaccessible"]
    private var selectedFeature:AGSFeature!
    private let optionsSegueName = "OptionsSegue"
    
    private let FEATURE_SERVICE_URL = "http://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditAttributesViewController", "EAOptionsViewController"]
        
        self.map = AGSMap(basemap: AGSBasemap.oceansBasemap())
        //set initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: 544871.19, y: 6806138.66, spatialReference: AGSSpatialReference.webMercator()), scale: 2e6)
        
        self.featureTable = AGSServiceFeatureTable(URL: NSURL(string: FEATURE_SERVICE_URL)!)
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        
        self.map.operationalLayers.addObject(self.featureLayer)
        
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showCallout(feature:AGSFeature, tapLocation:AGSPoint?) {
        let title = feature.attributeValueForKey("typdamage") as! String
        self.mapView.callout.title = title
        self.mapView.callout.delegate = self
        self.mapView.callout.showCalloutForFeature(feature, layer: self.featureLayer, tapLocation: tapLocation, animated: true)
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView, didTapAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        if let lastQuery = self.lastQuery{
            lastQuery.cancel()
        }
        
        //hide the callout
        self.mapView.callout.dismiss()
        
        self.lastQuery = self.mapView.identifyLayer(self.featureLayer, screenPoint: screen, tolerance: 5, maximumResults: 1) { [weak self] (identifyLayerResult: AGSIdentifyLayerResult?, error: NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else if let features = identifyLayerResult?.geoElements as? [AGSArcGISFeature] where features.count > 0 {
                //show callout for the first feature
                self?.showCallout(features[0], tapLocation: mappoint)
                //update selected feature
                self?.selectedFeature = features[0]
            }
        }
    }
    
    
    //MARK: - AGSCalloutDelegate
    
    func didTapAccessoryButtonForCallout(callout: AGSCallout) {
        //hide the callout
        self.mapView.callout.dismiss()
        //show editing options
        self.performSegueWithIdentifier(self.optionsSegueName, sender: self)
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == self.optionsSegueName {
            let controller = segue.destinationViewController as! EAOptionsViewController
            controller.options = self.types
            controller.delegate = self
        }
    }
    
    //MARK: - EAOptionsVCDelegate
    
    func optionsViewController(optionsViewController: EAOptionsViewController, didSelectOptionAtIndex index: Int) {
        self.selectedFeature.setAttributeValue(self.types[index], forKey: "typdamage")
        self.featureTable.updateFeature(self.selectedFeature) { [weak self] (error: NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else {
                self?.featureTable.applyEditsWithCompletion({ (result:[AGSFeatureEditResult]?, error:NSError?) -> Void in
                    if let error = error {
                        print(error)
                    }
                    else {
                        self?.showCallout(self!.selectedFeature, tapLocation: nil)
                    }
                })
            }
        }
    }
}
