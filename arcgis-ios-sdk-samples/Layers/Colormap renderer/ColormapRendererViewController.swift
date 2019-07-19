//
// Copyright 2019 Esri.
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

class ColormapRendererViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView! {
        didSet {
            //assign map to the map view
            mapView.map = AGSMap(basemap: .imagery())
            
            //add the raster layer to the operational layers of the map
            mapView.map?.operationalLayers.add(makeRasterLayer())
        }
    }
    
    private func makeRasterLayer() -> AGSRasterLayer {
        let raster = AGSRaster(name: "ShastaBW", extension: "tif")
        print("Inside rasterLayer")
        
        //create raster layer using raster
        let rasterLayer = AGSRasterLayer(raster: raster)
        //make two arrays with repeating initializer then appened them to get one array and add it to colormaprenderer
        
        let colors = Array(repeating: 10, count: 150)
        
        //set map view's viewpoint to the raster layer's full extent
        rasterLayer.load { [weak self] (error) in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                if let center = rasterLayer.fullExtent?.center {
                    self?.mapView.setViewpoint(AGSViewpoint(center: center, scale: 80000))
                }
            }
        }
        return rasterLayer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Inside viewDidLoad")
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ColormapRendererViewController"]
    }
}
