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
    
    private var featureLayer:AGSFeatureLayer?
    // the query is retained internally by the SDK so use a weak reference
    private weak var activeSelectionQuery:AGSCancelable?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FLSelectionViewController"]
        
        //initialize map with topographic basemap
        let map = AGSMap(basemap: .streets())
        //initial viewpoint
        map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(xMin: -180, yMin: -90, xMax: 180, yMax: 90, spatialReference: AGSSpatialReference.wgs84()))
        
        //assign map to the map view
        mapView.map = map
        mapView.touchDelegate = self
        
        let featureServiceURL = URL(string: "https://services1.arcgis.com/4yjifSiIG17X0gW4/arcgis/rest/services/GDP_per_capita_1960_2016/FeatureServer/0")!
        
        //create feature table using a url
        let featureTable = AGSServiceFeatureTable(url: featureServiceURL)
        
        //create feature layer using this feature table
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        self.featureLayer = featureLayer
        
        //add feature layer to the map
        map.operationalLayers.add(featureLayer)
        
        mapView.selectionProperties.color = .cyan
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        
        //cancel the active query if it hasn't been completed yet
        if let activeSelectionQuery = activeSelectionQuery{
            activeSelectionQuery.cancel()
        }
        
        guard let map = mapView.map,
            let featureLayer = featureLayer else{
                return
        }
        
        //tolerance level
        let toleranceInPoints: Double = 12
        //use tolerance to compute the envelope for query
        let toleranceInMapUnits = toleranceInPoints * mapView.unitsPerPoint
        let envelope = AGSEnvelope(xMin: mapPoint.x - toleranceInMapUnits,
                                   yMin: mapPoint.y - toleranceInMapUnits,
                                   xMax: mapPoint.x + toleranceInMapUnits,
                                   yMax: mapPoint.y + toleranceInMapUnits,
                                   spatialReference: map.spatialReference)
        
        //create query parameters object
        let queryParams = AGSQueryParameters()
        queryParams.geometry = envelope
        
        //run the selection query
        activeSelectionQuery = featureLayer.selectFeatures(withQuery: queryParams, mode: .new) { [weak self] (queryResult: AGSFeatureQueryResult?, error: Error?) -> Void in
            
            if let error = error {
                self?.presentAlert(error: error)
            }
            if let result = queryResult {
                print("\(result.featureEnumerator().allObjects.count) feature(s) selected")
            }
        }
    }
    
}
