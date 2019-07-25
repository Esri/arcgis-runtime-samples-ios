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
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Assign map to the map view.
            mapView.map = AGSMap(basemap: .imagery())
            
            // Create and add the raster layer to the operational layers of the map.
            mapView.map?.operationalLayers.add(makeRasterLayer())
        }
    }
    
    private func makeRasterLayer() -> AGSRasterLayer {
        let raster = AGSRaster(name: "ShastaBW", extension: "tif")
        
        // Create raster layer using raster.
        let rasterLayer = AGSRasterLayer(raster: raster)
        
        // Make two arrays to represent two different colors then appened them together.
        let colors = Array(repeating: UIColor.red, count: 150) + Array(repeating: UIColor.yellow, count: 151)
        
        // Render the colormap using the array of colors.
        let colormapRenderer = AGSColormapRenderer(colors: colors)
        rasterLayer.renderer = colormapRenderer
        
        // Set map view's viewpoint to the raster layer's full extent.
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
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ColormapRendererViewController"]
    }
}
