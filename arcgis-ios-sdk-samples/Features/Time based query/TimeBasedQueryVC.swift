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
//

import UIKit
import ArcGIS

class TimeBasedQueryVC: UIViewController {
    
    @IBOutlet var mapView: AGSMapView!
    
    private var map:AGSMap!
    
    private var featureTable:AGSServiceFeatureTable!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //initialize map with oceans basemap
        self.map = AGSMap(basemap: AGSBasemap.oceans())
        
        //assign map to the map view
        self.mapView.map = self.map
        
        //create feature table using a url
        self.featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Hurricanes/MapServer/0")!)
        
        //define the request mode
        self.featureTable.featureRequestMode = .manualCache
        
        //create feature layer using the feature table
        let layer = AGSFeatureLayer(featureTable: self.featureTable)
        
        //add feature layer to map's operational layers
        self.map.operationalLayers.add(layer)
        
        //populate features based on a time-based query
        self.populateFeaturesWithQuery()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["TimeBasedQueryVC"]
    }
    
    func populateFeaturesWithQuery(){
        
        //create query parameters
        let queryParams = AGSQueryParameters()

        //create a new time extent that covers the desired interval from September 1st to September 22th, 2000
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        let startTime = formatter.date(from: "2000/9/1 00:00")
        let endTime = formatter.date(from: "2000/9/22 00:00")
        
        let timeExtent = AGSTimeExtent(startTime: startTime, endTime: endTime)
        
        //apply the time extent to query parameters to filter features based on time
        queryParams.timeExtent = timeExtent
        
        //populate features based on query parameters
        self.featureTable.populateFromService(with: queryParams, clearCache: true, outFields: ["*"]) { (result:AGSFeatureQueryResult?, error:Error?) -> Void in
            
            //check for error
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription, maskType: .gradient)
            }
            else {
                //the resulting features should be displayed on the map
                //you can print the count of features
                print("Hurriance features during the time interval: \(result?.featureEnumerator().allObjects.count ?? 0)")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
