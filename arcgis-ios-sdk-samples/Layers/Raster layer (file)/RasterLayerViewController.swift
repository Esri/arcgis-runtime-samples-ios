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

class RasterLayerViewController: UIViewController {
    
    @IBOutlet private weak var mapView: AGSMapView!

    private var map:AGSMap!
    
    private var rasterLayer: AGSRasterLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["RasterLayerViewController"]
        
        //create raster
        let raster = AGSRaster(name: "Shasta", extension: "tif")
        
        //create raster layer using raster
        self.rasterLayer = AGSRasterLayer(raster: raster)
        
        //initialize map with raster layer as the basemap
        self.map = AGSMap(basemap: AGSBasemap.imagery())
        
        //assign map to the map view
        self.mapView.map = map
        
        //add the raster layer to the operational layers of the map
        self.mapView.map?.operationalLayers.add(rasterLayer!)
        
        //set map view's viewpoint to the raster layer's full extent
        self.rasterLayer.load { [weak self] (error) in
            
            guard error == nil else {
                SVProgressHUD.show(withStatus: error!.localizedDescription)
                return
            }
            
            if let center = self?.rasterLayer.fullExtent?.center {
                self?.mapView.setViewpoint(AGSViewpoint(center: center, scale: 80000))
            }
        }
    }
}
