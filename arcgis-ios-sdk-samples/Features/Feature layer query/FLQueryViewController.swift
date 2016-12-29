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

class FLQueryViewController: UIViewController, UISearchBarDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var featureTable:AGSServiceFeatureTable!
    private var featureLayer:AGSFeatureLayer!
    
    private var selectedFeatures = [AGSFeature]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FLQueryViewController"]
        
        //initialize map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.topographicBasemap())
        //assign map to the map view
        self.mapView.map = self.map
        
        //create feature table using a url
        self.featureTable = AGSServiceFeatureTable(URL: NSURL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/USA/MapServer/2")!)
        //create feature layer using this feature table
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        self.featureLayer.selectionWidth = 5
        
        //set a new renderer
        let lineSymbol = AGSSimpleLineSymbol(style: .Solid, color: UIColor.blackColor(), width: 1)
        let fillSymbol = AGSSimpleFillSymbol(style: .Solid, color: UIColor.yellowColor().colorWithAlphaComponent(0.5), outline: lineSymbol)
        self.featureLayer.renderer = AGSSimpleRenderer(symbol: fillSymbol)
        
        //add feature layer to the map
        self.map.operationalLayers.addObject(self.featureLayer)
        //zoom to a custom viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -11e6, y: 5e6, spatialReference: AGSSpatialReference.webMercator()), scale: 9e7, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func queryForState(state:String) {
        //un select if any features already selected
        if self.selectedFeatures.count > 0 {
            self.featureLayer.unselectFeatures(self.selectedFeatures)
        }
        
        let queryParams = AGSQueryParameters()
        queryParams.whereClause = "upper(STATE_NAME) LIKE '%\(state.uppercaseString)%'"

        self.featureTable.queryFeaturesWithParameters(queryParams, completion: { [weak self] (result:AGSFeatureQueryResult?, error:NSError?) -> Void in
            if let error = error {
                print(error.localizedDescription)
                //update selected features array
                self?.selectedFeatures.removeAll(keepCapacity: false)
            }
            else if let features = result?.featureEnumerator().allObjects {
                if features.count > 0 {
                    self?.featureLayer.selectFeatures(features)
                    //zoom to the selected feature
                    self?.mapView.setViewpointGeometry(features[0].geometry!, padding: 80, completion: nil)
                }
                else {
                    SVProgressHUD.showErrorWithStatus("No state by that name", maskType: .Gradient)
                }
                //update selected features array
                self?.selectedFeatures = features 
            }
        })
    }
    
    //MARK: - Search bar delegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if let text = searchBar.text {
            self.queryForState(text)
        }
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
