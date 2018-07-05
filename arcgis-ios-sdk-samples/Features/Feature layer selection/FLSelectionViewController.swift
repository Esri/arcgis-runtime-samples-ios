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

class FLSelectionViewController: UIViewController, AGSGeoViewTouchDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var featureTable:AGSServiceFeatureTable!
    private var featureLayer:AGSFeatureLayer!
    private var lastQuery:AGSCancelable!
    private var selectedFeatures:[AGSFeature]!
    private let FEATURE_SERVICE_URL = "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FLSelectionViewController"]
        
        //initialize map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.streets())
        //initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -1131596.019761, yMin: 3893114.069099, xMax: 3926705.982140, yMax: 7977912.461790, spatialReference: AGSSpatialReference.webMercator()))
        //assign map to the map view
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
        //create feature table using a url
        self.featureTable = AGSServiceFeatureTable(url: URL(string: FEATURE_SERVICE_URL)!)
        //create feature layer using this feature table
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        self.featureLayer.selectionColor = .cyan
        self.featureLayer.selectionWidth = 3
        //add feature layer to the map
        self.map.operationalLayers.add(self.featureLayer)
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let lastQuery = self.lastQuery{
            lastQuery.cancel()
        }
        
        let tolerance:Double = 12
        let mapTolerance = tolerance * self.mapView.unitsPerPoint
        let envelope = AGSEnvelope(xMin: mapPoint.x - mapTolerance,
            yMin: mapPoint.y - mapTolerance,
            xMax: mapPoint.x + mapTolerance,
            yMax: mapPoint.y + mapTolerance,
            spatialReference: self.map.spatialReference)
        
        let queryParams = AGSQueryParameters()
        queryParams.geometry = envelope
        
        self.featureLayer.selectFeatures(withQuery: queryParams, mode: AGSSelectionMode.new) { (queryResult:AGSFeatureQueryResult?, error:Error?) -> Void in
            if let error = error {
                print(error)
            }
            if let result = queryResult {
                print("\(result.featureEnumerator().allObjects.count) feature(s) selected")
            }
        }
    }
}
