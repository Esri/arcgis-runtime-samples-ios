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

class EditAttributesViewController: UIViewController, AGSGeoViewTouchDelegate, AGSCalloutDelegate, EAOptionsVCDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var featureTable:AGSServiceFeatureTable!
    private var featureLayer:AGSFeatureLayer!
    private var lastQuery:AGSCancelable!
    
    private var types = ["Destroyed", "Major", "Minor", "Affected", "Inaccessible"]
    private var selectedFeature:AGSArcGISFeature!
    private let optionsSegueName = "OptionsSegue"
    
    private let FEATURE_SERVICE_URL = "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditAttributesViewController", "EAOptionsViewController"]
        
        self.map = AGSMap(basemap: .oceans())
        //set initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: 544871.19, y: 6806138.66, spatialReference: AGSSpatialReference.webMercator()), scale: 2e6)
        
        self.featureTable = AGSServiceFeatureTable(url: URL(string: FEATURE_SERVICE_URL)!)
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        
        self.map.operationalLayers.add(self.featureLayer)
        
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
    }
    
    func showCallout(_ feature:AGSFeature, tapLocation:AGSPoint?) {
        let title = feature.attributes["typdamage"] as! String
        self.mapView.callout.title = title
        self.mapView.callout.delegate = self
        self.mapView.callout.show(for: feature, tapLocation: tapLocation, animated: true)
    }
    
    func applyEdits() {
        SVProgressHUD.show(withStatus: "Applying edits")
        
        self.featureTable.applyEdits(completion: { [weak self] (result:[AGSFeatureEditResult]?, error:Error?) -> Void in
            if let error = error {
                self?.presentAlert(error: error)
            }
            else {
                self?.presentAlert(message: "Edits applied successfully")
                self?.showCallout(self!.selectedFeature, tapLocation: nil)
            }
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
                //show callout for the first feature
                self?.showCallout(features[0], tapLocation: mapPoint)
                //update selected feature
                self?.selectedFeature = features[0]
            }
        }
    }
    
    
    //MARK: - AGSCalloutDelegate
    
    func didTapAccessoryButton(for callout: AGSCallout) {
        //hide the callout
        self.mapView.callout.dismiss()
        //show editing options
        self.performSegue(withIdentifier: self.optionsSegueName, sender: self)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.optionsSegueName {
            let controller = segue.destination as! EAOptionsViewController
            controller.options = self.types
            controller.delegate = self
        }
    }
    
    //MARK: - EAOptionsVCDelegate
    
    func optionsViewController(_ optionsViewController: EAOptionsViewController, didSelectOptionAtIndex index: Int) {
        SVProgressHUD.show(withStatus: "Updating")
        
        self.selectedFeature.attributes["typdamage"] = self.types[index]
        self.featureTable.update(self.selectedFeature) { [weak self] (error: Error?) -> Void in
            if let error = error {
                self?.presentAlert(error: error)
            }
            else {
                self?.applyEdits()
            }
        }
    }
}
