//
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
//

import UIKit
import ArcGIS

class AddDeleteRelatedFeaturesVC: UIViewController, AGSGeoViewTouchDelegate, AGSCalloutDelegate {

    @IBOutlet var mapView:AGSMapView!
    
    private var parksFeatureTable:AGSServiceFeatureTable!
    private var speciesFeatureTable:AGSServiceFeatureTable!
    private var parksFeatureLayer:AGSFeatureLayer!
    private var relatedFeatures:[AGSFeature]!
    
    private var selectedPark:AGSFeature!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["AddDeleteRelatedFeaturesVC", "RelatedFeaturesViewController"]

        //initialize map with basemap
        let map = AGSMap(basemap: .streets())
        
        //initial viewpoint
        let point = AGSPoint(x: -16507762.575543, y: 9058828.127243, spatialReference: AGSSpatialReference(wkid: 3857))
        
        //set initial viewpoint on map
        map.initialViewpoint = AGSViewpoint(center: point, scale: 36764077)
        
        //parks feature table
        self.parksFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/AlaskaNationalParksSpecies_Add_Delete/FeatureServer/0")!)
        
        //parks feature layer
        self.parksFeatureLayer = AGSFeatureLayer(featureTable: self.parksFeatureTable)
        
        //add feature layer to the map
        map.operationalLayers.add(self.parksFeatureLayer)
        
        //species feature table (destination feature table)
        //related to the parks feature layer in a 1..M relationship
        self.speciesFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/ArcGIS/rest/services/AlaskaNationalParksSpecies_Add_Delete/FeatureServer/1")!)
        
        //add table to the map
        //for the related query to work, the related table should be present in the map
        map.tables.addObjects(from: [speciesFeatureTable])
        
        //assign map to map view
        self.mapView.map = map
        
        //set touch delegate
        self.mapView.touchDelegate = self
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        //show progress hud for identify
        SVProgressHUD.show(withStatus: "Identifying feature")
        
        //identify features at tapped location
        self.mapView.identifyLayer(self.parksFeatureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false) { [weak self] (result) in
            
            guard result.error == nil else {
                
                //show error to user
                self?.presentAlert(error: result.error!)
                return
            }
            
            //hide progress hud
            SVProgressHUD.dismiss()
            
            if result.geoElements.count > 0 {
                
                //select the first feature
                let feature = result.geoElements[0] as! AGSFeature
                self?.selectedPark = feature
                
                //show related features view controller
                self?.performSegue(withIdentifier: "RelatedFeaturesSegue", sender: self)
            }
        }
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "RelatedFeaturesSegue" {
            
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.viewControllers[0] as! RelatedFeaturesViewController
            
            //share selected park
            controller.originFeature = self.selectedPark as? AGSArcGISFeature
            
            //share parks feature table as origin feature table
            controller.originFeatureTable = self.parksFeatureTable
        }
    }
}
