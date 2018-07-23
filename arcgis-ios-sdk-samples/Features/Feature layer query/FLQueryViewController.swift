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
        self.map = AGSMap(basemap: AGSBasemap.topographic())
        //assign map to the map view
        self.mapView.map = self.map
        
        //create feature table using a url
        self.featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/USA/MapServer/2")!)
        //create feature layer using this feature table
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        self.featureLayer.selectionWidth = 5
        
        //set a new renderer
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .black, width: 1)
        let fillSymbol = AGSSimpleFillSymbol(style: .solid, color: UIColor.yellow.withAlphaComponent(0.5), outline: lineSymbol)
        self.featureLayer.renderer = AGSSimpleRenderer(symbol: fillSymbol)
        
        //add feature layer to the map
        self.map.operationalLayers.add(self.featureLayer)
        //zoom to a custom viewpoint
        self.mapView.setViewpointCenter(AGSPoint(x: -11e6, y: 5e6, spatialReference: AGSSpatialReference.webMercator()), scale: 9e7, completion: nil)
    }
    
    func queryForState(_ state:String) {
        //un select if any features already selected
        if self.selectedFeatures.count > 0 {
            self.featureLayer.unselectFeatures(self.selectedFeatures)
        }
        
        let queryParams = AGSQueryParameters()
        queryParams.whereClause = "upper(STATE_NAME) LIKE '%\(state.uppercased())%'"

        self.featureTable.queryFeatures(with: queryParams, completion: { [weak self] (result:AGSFeatureQueryResult?, error:Error?) -> Void in
            if let error = error {
                print(error.localizedDescription)
                //update selected features array
                self?.selectedFeatures.removeAll(keepingCapacity: false)
            }
            else if let features = result?.featureEnumerator().allObjects {
                if features.count > 0 {
                    self?.featureLayer.select(features)
                    //zoom to the selected feature
                    self?.mapView.setViewpointGeometry(features[0].geometry!, padding: 80, completion: nil)
                }
                else {
                    SVProgressHUD.showError(withStatus: "No state by that name")
                }
                //update selected features array
                self?.selectedFeatures = features 
            }
        })
    }
    
    //MARK: - Search bar delegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            self.queryForState(text)
        }
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
