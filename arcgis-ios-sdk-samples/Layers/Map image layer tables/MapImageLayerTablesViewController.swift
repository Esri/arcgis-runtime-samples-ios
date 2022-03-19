// Copyright 2022 Esri.
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

class MapImageLayerTablesViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    
    static let serviceRequestURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/ServiceRequest/MapServer")!
    let serviceRequestsMapImageLayer = AGSArcGISMapImageLayer(url: serviceRequestURL)
    let selectedFeaturesOverlay = AGSGraphicsOverlay()
    
    func makeMap() -> AGSMap{
        let map = AGSMap(basemapStyle: .arcGISStreets)
        let requestsExtent = serviceRequestsMapImageLayer.fullExtent!
        map.initialViewpoint = AGSViewpoint(targetExtent: requestsExtent)
        map.operationalLayers.add(serviceRequestsMapImageLayer)
        return map
    }
    
    func queryFeatures() {
        let commentsTable = serviceRequestsMapImageLayer.tables.first
        let nullCommentsParameters = AGSQueryParameters()
        nullCommentsParameters.whereClause = "requestid <> '' AND comments <> ''"
        
        let commentQueryResult = commentsTable?.queryFeatures(with: nullCommentsParameters, queryFeatureFields: .loadAll) { result, error in
            // Show the records from the service request comments table in the list view control.
            
            // Create a graphics overlay to show selected features and add it to the map view.
            
            // Assign the map to the MapView.
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [ "MapImageLayerTablesViewController"]
    }
}
