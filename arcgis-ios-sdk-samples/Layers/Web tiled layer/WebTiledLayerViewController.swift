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

class WebTiledLayerViewController: UIViewController {

    @IBOutlet private var mapView:AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["WebTiledLayerViewController"]

        //url template for web tiled layer
        let urlTemplate = "http://{subDomain}.tile.stamen.com/terrain/{level}/{col}/{row}.png"
        
        //sub domains
        let subDomains = ["a", "b", "c", "d"]
        
        //attribution
        let attribution = "Map tiles by <a href=\"http://stamen.com/\">Stamen Design</a>, "
            + "under <a href=\"http://creativecommons.org/licenses/by/3.0\">CC BY 3.0</a>. "
            + "Data by <a href=\"http://openstreetmap.org/\">OpenStreetMap</a>, "
            + "under <a href=\"http://creativecommons.org/licenses/by-sa/3.0\">CC BY SA</a>."
        
        //initialize web tiled layer
        let webTiledLayer = AGSWebTiledLayer(urlTemplate: urlTemplate, subDomains: subDomains)
        
        //assign attribution
        webTiledLayer.attribution = attribution
        
        //initialize basemap with web tiled layer
        let basemap = AGSBasemap(baseLayer: webTiledLayer)
        
        //initialize map with the basemap
        let map = AGSMap(basemap: basemap)
        
        //initial viewpoint
        let centerPoint = AGSPoint(x: -13167861.0, y: 4382202.0, spatialReference: AGSSpatialReference.webMercator())
        
        //set initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: centerPoint, scale: 50000)
        
        //assign map to the map view
        self.mapView.map = map
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
