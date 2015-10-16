// Copyright 2015 Esri.
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

class FLSelectionViewController: UIViewController, AGSMapViewTouchDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var featureTable:AGSServiceFeatureTable!
    private var featureLayer:AGSFeatureLayer!
    private var lastQuery:AGSCancellable!
    private var selectedFeatures:[AGSFeature]!
    private let FEATURE_SERVICE_URL = "http://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FLSelectionViewController"]
        
        //initialize map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.streetsBasemap())
        //initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(XMin: -1131596.019761, yMin: 3893114.069099, xMax: 3926705.982140, yMax: 7977912.461790, spatialReference: AGSSpatialReference.webMercator()))
        //assign map to the map view
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
        //create feature table using a url
        self.featureTable = AGSServiceFeatureTable(URL: NSURL(string: FEATURE_SERVICE_URL)!)
        //create feature layer using this feature table
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        self.featureLayer.selectionColor = UIColor.cyanColor()
        self.featureLayer.selectionWidth = 3
        //add feature layer to the map
        self.map.operationalLayers.addObject(self.featureLayer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView, didTapAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        if let lastQuery = self.lastQuery{
            lastQuery.cancel()
        }
        
        let tolerance:Double = 22
        let mapTolerance = tolerance * self.mapView.unitsPerPixel
        let envelope = AGSEnvelope(XMin: mappoint.x - mapTolerance,
            yMin: mappoint.y - mapTolerance,
            xMax: mappoint.x + mapTolerance,
            yMax: mappoint.y + mapTolerance,
            spatialReference: self.map.spatialReference)
        
        let queryParams = AGSQueryParameters()
        queryParams.geometry = envelope
        queryParams.outFields = ["*"]
        
        self.featureLayer.selectFeaturesWithQuery(queryParams, mode: AGSSelectionMode.New) { (queryResult:AGSFeatureQueryResult?, error:NSError?) -> Void in
            if let error = error {
                print(error)
            }
            if let result = queryResult, enumerator = result.enumerator() {
                print("\(enumerator.allObjects.count) feature(s) selected")
            }
        }
    }
}
