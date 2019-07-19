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
            mapView.map?.operationalLayers.add(makeLayer())
            
//            mapView.setViewpoint(rasterLayer.fullExtent)
            print("Inside mapView")
        }
    }
    
//    private var map: AGSMap! {
//        didSet {
//            //initialize map with raster layer as the basemap
//            map = AGSMap(basemap: .imagery())
//            print("Inside map")
//        }
//    }
    
    private func makeLayer() -> AGSRasterLayer {
        let raster = AGSRaster(name: "ShastaBW", extension: "tif")
        print("Inside rasterLayer")
        
        //create raster layer using raster
        var rasterLayer: AGSRasterLayer!
        rasterLayer = AGSRasterLayer(raster: raster)
        
        
        //set map view's viewpoint to the raster layer's full extent
        rasterLayer.load { [weak self] (error) in
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                if let center = self?.rasterLayer.fullExtent?.center {
                    self?.mapView.setViewpoint(AGSViewpoint(center: center, scale: 80000))
                }
            }
        }
        return AGSRasterLayer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Inside viewDidLoad")
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ColormapRendererViewController"]
    }
}
