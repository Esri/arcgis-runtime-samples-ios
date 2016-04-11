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
    
    private var navigationURLString = "http://www.arcgis.com/home/item.html?id=00cd8e843bae49b3a040423e5d65416b"
    private var streetsURLString = "http://www.arcgis.com/home/item.html?id=3b8814f6ddbd485cae67e8018992246e"
    private var nightURLString = "http://www.arcgis.com/home/item.html?id=f96366254a564adda1dc468b447ed956"
    private var darkGrayURLString = "http://www.arcgis.com/sharing/rest/content/items/3e3099d7302f4d99bc6f916dcc07ed59"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["VectorTileLayerViewController"]
        
        //create a vector tiled layer
        let vectorTileLayer = AGSArcGISVectorTiledLayer(URL: NSURL(string: navigationURLString)!)
        //create a map and set the vector tiled layer as the basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: vectorTileLayer))
        
        //assign the map to the map view
        self.mapView.map = map
        
        //enable rotation
        self.mapView.allowInteractiveRotation = true

        //center on Miami, Fl
        self.mapView.setViewpointCenter(AGSPoint(x: -80.18, y: 25.778135, spatialReference: AGSSpatialReference.WGS84()), scale: 150000, completion: nil)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func segmentedControlChanged(sender:UISegmentedControl) {
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
        let vectorTileLayer = AGSArcGISVectorTiledLayer(URL: NSURL(string: urlString)!)
        //change the basemap to the new layer
        self.mapView.map?.basemap = AGSBasemap(baseLayer: vectorTileLayer)
    }
}
