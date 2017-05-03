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

class ListRelatedFeaturesVC: UIViewController, AGSGeoViewTouchDelegate, UIPopoverPresentationControllerDelegate {

    @IBOutlet var mapView:AGSMapView!
    
    var parksFeatureLayer:AGSFeatureLayer!
    var parksFeatureTable:AGSServiceFeatureTable!
    var preservesFeatureTable:AGSServiceFeatureTable!
    var speciesFeatureTable:AGSServiceFeatureTable!
    private var selectedPark:AGSArcGISFeature!
    private var screenPoint:CGPoint!
    
    private var results:[AGSRelatedFeatureQueryResult]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ListRelatedFeaturesVC", "RelatedFeaturesListVC"]
        
        //initialize map with a basemap
        let map = AGSMap(basemap: AGSBasemap.topographic())
        
        //initial viewpoint
        let point = AGSPoint(x: -16507762.575543, y: 9058828.127243, spatialReference: AGSSpatialReference(wkid: 3857))
        //set initial viewpoint on map
        map.initialViewpoint = AGSViewpoint(center: point, scale: 36764077)
        
        //add self as the touch delegate for map view
        //we will need to be notified when the user taps with the map
        self.mapView.touchDelegate = self
        
        //create feature table for the parks layer, the origin layer in the relationship
        self.parksFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/AlaskaNationalParksPreservesSpecies_List/FeatureServer/1")!)
        
        //feature layer for parks
        self.parksFeatureLayer = AGSFeatureLayer(featureTable: self.parksFeatureTable)
        
        //add parks feature layer to the map
        map.operationalLayers.add(self.parksFeatureLayer)
        
        //Feature table for related Preserves layer
        self.preservesFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/AlaskaNationalParksPreservesSpecies_List/FeatureServer/0")!)
        
        //Feature table for related Species layer
        self.speciesFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/AlaskaNationalParksPreservesSpecies_List/FeatureServer/2")!)
        
        //add these to the tables on the map
        //to query related features in a layer, the layer must either be added as a feature
        //layer in operational layers or as a feature table in tables on map
        map.tables.addObjects(from: [preservesFeatureTable, speciesFeatureTable])
        
        //assign map to the map view
        self.mapView.map = map
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Identifying feature", maskType: .gradient)
        
        //identify features at the tapped location
        self.mapView.identifyLayer(self.parksFeatureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] (result: AGSIdentifyLayerResult) in
            
            if let error = result.error {
                
                //dismiss progress hud
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            else {
                
                //dismiss progress hud
                SVProgressHUD.dismiss()
                
                //Check if a feature is identified
                if result.geoElements.count > 0 {
                    
                    //select the first feature
                    let feature = result.geoElements[0] as! AGSArcGISFeature
                    
                    //store as selected park to use for querying
                    self?.selectedPark = feature
                    
                    //store the screen point for the tapped location to show popover at that location
                    self?.screenPoint = screenPoint
                    
                    //query for related features
                    self?.queryRelatedFeatures()
                }
            }
        }
    }

    //query for related features given the origin feature
    private func queryRelatedFeatures() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Querying related features", maskType: .gradient)
        
        //query for related features
        self.parksFeatureTable.queryRelatedFeatures(for: self.selectedPark) { [weak self] (results:[AGSRelatedFeatureQueryResult]?, error:Error?) in
            
            if let error = error {
                
                //display error
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            else {
                
                //dismiss progress hud
                SVProgressHUD.dismiss()
                
                //Show the related features found in popover
                if let results = results, results.count > 0 {
                    self?.results = results
                    
                    //self?.performSegue(withIdentifier: "RelatedFeaturesSegue", sender: self)
                    self?.showRelatedFeatures()
                }
                else {  //else notify user
                    SVProgressHUD.showInfo(withStatus: "No related features found", maskType: .gradient)
                }
            }
        }
    }
    
    //show related features in a table view as popover
    private func showRelatedFeatures() {
        
        //instantiate the view controller from storyboard
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "RelatedFeaturesListVC") as! RelatedFeaturesListVC
        
        //set results from related features query
        controller.results = self.results
        
        //set presentation style to popover, for inline display
        controller.modalPresentationStyle = .popover
        
        //other settings for popover
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        controller.popoverPresentationController?.sourceView = self.mapView
        controller.popoverPresentationController?.sourceRect = CGRect(origin: self.screenPoint, size: CGSize.zero)
        controller.popoverPresentationController?.delegate = self
        
        //present the controller
        self.present(controller, animated: true, completion: nil)
    }
    
    //MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.none
    }
    
    //to hide popover controller on rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
