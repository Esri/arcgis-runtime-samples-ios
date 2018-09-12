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

class FeatureCollectionLayerQueryVC: UIViewController {

    @IBOutlet var mapView:AGSMapView!
    
    private var featureTable:AGSServiceFeatureTable!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FeatureCollectionLayerQueryVC"]
        
        //initialize map with basemap
        let map = AGSMap(basemap: .oceans())
        
        //assign map to the map view
        self.mapView.map = map
        
        //initialize service feature table to be queried
        self.featureTable = AGSServiceFeatureTable(url: URL(string: "http://sampleserver6.arcgisonline.com/arcgis/rest/services/Wildfire/FeatureServer/0")!)
        
        //create query parameters
        let queryParams = AGSQueryParameters()
        
        // 1=1 will give all the features from the table
        queryParams.whereClause = "1=1"
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Querying")
        
        //query feature from the table
        self.featureTable.queryFeatures(with: queryParams) { [weak self] (queryResult: AGSFeatureQueryResult?, error: Error?) in
            
            if let error = error {
                //show error
                SVProgressHUD.show(withStatus: error.localizedDescription)
            }
            else {
                //hide progress hud
                SVProgressHUD.dismiss()
                
                //create a feature collection table fromt the query results
                let featureCollectionTable = AGSFeatureCollectionTable(featureSet: queryResult!)
                
                //create a feature collection from the above feature collection table
                let featureCollection = AGSFeatureCollection(featureCollectionTables: [featureCollectionTable])
                
                //create a feature collection layer
                let featureCollectionLayer = AGSFeatureCollectionLayer(featureCollection: featureCollection)
                
                //add the layer to the operational layers array
                self?.mapView.map?.operationalLayers.add(featureCollectionLayer)
            }
        }
    }
    
}
