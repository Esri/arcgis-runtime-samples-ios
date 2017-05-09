//
// Copyright 2017 Esri.
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

class UpdateRelatedFeatureAttributeVC: UIViewController, AGSGeoViewTouchDelegate, AGSCalloutDelegate, AttributeValuesVCDelegate {
    
    @IBOutlet var mapView:AGSMapView!
    
    private var parksFeatureTable:AGSServiceFeatureTable!
    private var parksFeatureLayer:AGSFeatureLayer!
    private var preservesFeatureTable:AGSServiceFeatureTable!
    private var preservesFeatureLayer:AGSFeatureLayer!
    
    private var selectedPark:AGSArcGISFeature!
    private var relatedPreserve:AGSArcGISFeature!
    
    private var visitorsRange = ["0-1,000", "1,000-10,000", "10,000-50,000", "50,000-100,000", "500,000+"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["UpdateRelatedFeatureAttributeVC", "AttributeValuesViewController"]
        
        //initialize map with basemap
        let map = AGSMap(basemap: AGSBasemap.streets())
        
        //initial viewpoint
        let point = AGSPoint(x: -16907762.575543, y: 9058828.127243, spatialReference: AGSSpatialReference(wkid: 3857))
        map.initialViewpoint = AGSViewpoint(center: point, scale: 36764077)
        
        //create feature table for parks layer (origin)
        self.parksFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/AlaskaNationalParksPreserves_Update/FeatureServer/1")!)
        
        //feature layer for parks layer
        self.parksFeatureLayer = AGSFeatureLayer(featureTable: self.parksFeatureTable)
        
        //feature table for preserves layer (destination)
        self.preservesFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/AlaskaNationalParksPreserves_Update/FeatureServer/0")!)
        
        //feature layer for preserves
        self.preservesFeatureLayer = AGSFeatureLayer(featureTable: self.preservesFeatureTable)
        
        //selection settings
        self.preservesFeatureLayer.selectionWidth = 4
        
        //add layers as operational layers on map
        map.operationalLayers.addObjects(from: [self.parksFeatureLayer, self.preservesFeatureLayer])
        
        //assign map to map view
        self.mapView.map = map
        
        //set touch delegate for map view, to identify features on tap
        self.mapView.touchDelegate = self
    }
    
    private func queryRelatedFeatures(originFeature: AGSFeature) {
        
        SVProgressHUD.show(withStatus: "Querying related feature", maskType: .gradient)
        
        //query for related feature
        self.parksFeatureTable.queryRelatedFeatures(for: originFeature as! AGSArcGISFeature) { [weak self] (results:[AGSRelatedFeatureQueryResult]?, error:Error?) in
            
            if let error = error {
                //show error
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            else {
                
                //dismiss progress hud
                SVProgressHUD.dismiss()
                
                if let results = results, results.count > 0 {
                    
                    //since its a 1:1 relationship we will use the first related feature
                    if results[0].featureEnumerator().hasNextObject() {
                        
                        let preserve = results[0].featureEnumerator().nextObject() as! AGSArcGISFeature
                        
                        //keep a reference to it to be used later
                        self?.relatedPreserve = preserve
                        
                        //select preserve
                        self?.preservesFeatureLayer.select(preserve)
                        
                        //zoom in to the result and show callout
                        self?.zoomIn()
                        
                        return
                    }
                }
                
                //show error
                SVProgressHUD.showError(withStatus: "No related features found", maskType: .gradient)
            }
        }
    }
    
    private func zoomIn() {
        
        //create union of geometries of park and preserve
        let union = AGSGeometryEngine.unionGeometries([self.selectedPark.geometry!, self.relatedPreserve.geometry!])!
        
        //zoom in to the union of geometries
        self.mapView.setViewpointGeometry(union, padding: 30) { [weak self] (finished) in
            
            //show callout when zoom animation finishes
            self?.showCallout()
        }
    }
    
    private func showCallout() {
        
        //populate callout title and detail
        let detail = self.relatedPreserve.attributes["ANNUAL_VISITORS"] as! String

        self.mapView.callout.title = "Annual visitors to the preserve"
        self.mapView.callout.detail = "\(detail)"
        
        //custom image for accessory button on callout
        self.mapView.callout.accessoryButtonImage = UIImage(named: "EditIcon")
        
        //show callout
        self.mapView.callout.show(for: self.selectedPark, tapLocation: nil, animated: true)
        
        //set delegate to know when accessory button is tapped
        self.mapView.callout.delegate = self
    }
    
    private func applyEdits() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Apply edits", maskType: .gradient)
        
        //apply edits to the service
        self.preservesFeatureTable.applyEdits { [weak self] (results: [AGSFeatureEditResult]?, error: Error?) in
            
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            else {
                if let featureEditResults = results, featureEditResults.count > 0 && featureEditResults[0].completedWithErrors == false {
                    SVProgressHUD.showSuccess(withStatus: "Edits applied successfully")
                    
                    //show the updated info in callout
                    self?.showCallout()
                }
                else {
                    SVProgressHUD.showError(withStatus: "Error while apply edits", maskType: .gradient)
                }
            }
        }
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        //hide callout
        self.mapView.callout.dismiss()
        
        //unselect preserve
        if let preserve = self.relatedPreserve {
            self.preservesFeatureLayer.unselectFeature(preserve)
            self.relatedPreserve = nil
        }
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Identifying", maskType: .gradient)
        
        //identify features at tapped location
        self.mapView.identifyLayer(self.parksFeatureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] (result: AGSIdentifyLayerResult) in
            
            if let error = result.error {
                //show error
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            else {
                
                //dismiss progress hud
                SVProgressHUD.dismiss()
                
                if result.geoElements.count > 0 {
                    
                    //select the first feature
                    let feature = result.geoElements[0] as! AGSArcGISFeature
                    
                    //keep a reference to be used later
                    self?.selectedPark = feature
                    
                    //query for related features
                    self?.queryRelatedFeatures(originFeature: feature)
                }
            }
        }
    }
    
    //MARK: - AGSCalloutDelegate
    
    func didTapAccessoryButton(for callout: AGSCallout) {
        
        //dismiss callout
        self.mapView.callout.dismiss()
        
        //show options to choose from
        self.performSegue(withIdentifier: "AttributeValuesSegue", sender: self)
    }
    
    //MARK: - AttributeValuesVCDelegate
    
    func attributeValuesViewController(_ attributeValuesViewController: AttributeValuesViewController, didSelectValue value: String) {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Loading feature", maskType: .gradient)
        
        //load feature
        self.relatedPreserve.load { [weak self] (error: Error?) in
            
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            else {
                
                //update progress hud message
                SVProgressHUD.show(withStatus: "Updating feature", maskType: .gradient)
                
                //update the annual visitors to the selected value
                self?.relatedPreserve.attributes["ANNUAL_VISITORS"] = value
                
                //update feature on the table
                self?.preservesFeatureTable.update(self!.relatedPreserve) { (error:Error?) in
                    if let error = error {
                        SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
                    }
                    else {
                        //apply edits
                        self?.applyEdits()
                    }
                }
            }
        }
        
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "AttributeValuesSegue" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.viewControllers[0] as! AttributeValuesViewController
            controller.attributeValues = self.visitorsRange
            controller.preferredContentSize = CGSize(width: 300, height: 300)
            controller.delegate = self
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
