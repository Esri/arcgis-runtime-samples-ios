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

class DeleteFeaturesViewController: UIViewController, AGSGeoViewTouchDelegate, AGSCalloutDelegate {
    
    @IBOutlet private var mapView:AGSMapView!
    
    private var featureTable:AGSServiceFeatureTable!
    private var featureLayer:AGSFeatureLayer!
    private var lastQuery:AGSCancelable!
    private var selectedFeature:AGSFeature!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DeleteFeaturesViewController"]
        
        //instantiate map with a basemap
        let map = AGSMap(basemap: AGSBasemap.streets())
        //set initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: 544871.19, y: 6806138.66, spatialReference: AGSSpatialReference.webMercator()), scale: 2e6)
        
        //assign the map to the map view
        self.mapView.map = map
        //set touch delegate on map view as self
        self.mapView.touchDelegate = self
        
        //instantiate service feature table using the url to the service
        self.featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0")!)
        //create a feature layer using the service feature table
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        
        //add the feature layer to the operational layers on map
        map.operationalLayers.add(featureLayer)
    }
    
    func showCallout(for feature:AGSFeature,at tapLocation:AGSPoint) {
        let title = feature.attributes["typdamage"] as! String
        self.mapView.callout.title = title
        self.mapView.callout.delegate = self
        self.mapView.callout.accessoryButtonImage = UIImage(named: "Discard")
        self.mapView.callout.show(for: feature, tapLocation: tapLocation, animated: true)
    }
    
    func deleteFeature(_ feature:AGSFeature) {
        self.featureTable.delete(feature) { [weak self] (error: Error?) -> Void in
            if let error = error {
                print("Error while deleting feature : \(error.localizedDescription)")
            }
            else {
                self?.applyEdits()
            }
        }
    }
    
    func applyEdits() {
        self.featureTable.applyEdits { (featureEditResults: [AGSFeatureEditResult]?, error: Error?) -> Void in
            if let error = error {
                SVProgressHUD.showError(withStatus: "Error while applying edits :: \(error.localizedDescription)")
            }
            else {
                if let featureEditResults = featureEditResults , featureEditResults.count > 0 && featureEditResults[0].completedWithErrors == false {
                    SVProgressHUD.showSuccess(withStatus: "Edits applied successfully")
                }
            }
        }
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
            else if let features = identifyLayerResult.geoElements as? [AGSFeature] , features.count > 0 {
                //show callout for the first feature
                self?.showCallout(for: features[0], at: mapPoint)
                //update selected feature
                self?.selectedFeature = features[0]
            }
        }
    }
    
    //MARK: - AGSCalloutDelegate
    
    func didTapAccessoryButton(for callout: AGSCallout) {
        //hide the callout
        self.mapView.callout.dismiss()
        
        //confirmation
        let alertController = UIAlertController(title: "Are you sure you want to delete the feature", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        //action for Yes
        let alertAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) { [weak self] (action:UIAlertAction!) -> Void in
            self?.deleteFeature(self!.selectedFeature)
        }
        alertController.addAction(alertAction)
        
        //action for cancel
        let cancelAlertAction = UIAlertAction(title: "No", style: .cancel)
        alertController.addAction(cancelAlertAction)
        
        //present alert controller
        self.present(alertController, animated: true, completion: nil)
    }
}
