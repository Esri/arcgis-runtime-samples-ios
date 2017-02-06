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

class VectorTileLayerViewController: UIViewController {

    @IBOutlet var mapView:AGSMapView!
    
    private var navigationURLString = "https://www.arcgis.com/home/item.html?id=e19e9330bf08490ca8353d76b5e2e658"
    private var streetsURLString = "https://www.arcgis.com/home/item.html?id=a60a37a27cc140ddad15f919cd5a69f2"
    private var nightURLString = "https://www.arcgis.com/home/item.html?id=92c551c9f07b4147846aae273e822714"
    private var darkGrayURLString = "https://www.arcgis.com/home/item.html?id=5ad3948260a147a993ef4865e3fad476"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["VectorTileLayerViewController"]
        
        //create a vector tiled layer
        let vectorTileLayer = AGSArcGISVectorTiledLayer(url: URL(string: navigationURLString)!)
        //create a map and set the vector tiled layer as the basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: vectorTileLayer))
        
        //assign the map to the map view
        self.mapView.map = map

        //center on Miami, Fl
        self.mapView.setViewpointCenter(AGSPoint(x: -80.18, y: 25.778135, spatialReference: AGSSpatialReference.wgs84()), scale: 150000, completion: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func segmentedControlChanged(_ sender:UISegmentedControl) {
        var urlString:String
        switch sender.selectedSegmentIndex {
        case 0:
            urlString = navigationURLString
        case 1:
            urlString = streetsURLString
        case 2:
            urlString = nightURLString
        default:
            urlString = darkGrayURLString
        }
        
        //create the new vector tiled layer using the url
        let vectorTileLayer = AGSArcGISVectorTiledLayer(url: URL(string: urlString)!)
        //change the basemap to the new layer
        self.mapView.map?.basemap = AGSBasemap(baseLayer: vectorTileLayer)
    }
}
