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

class RasterLayerUsingServiceVC : UIViewController {
    
    @IBOutlet weak var mapView: AGSMapView!
    
    private var map:AGSMap!
    
    private var rasterLayer: AGSRasterLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //create an image service raster from an online raster service
        let imageServiceRaster = AGSImageServiceRaster(url: URL(string:"https://sampleserver6.arcgisonline.com/arcgis/rest/services/NLCDLandCover2001/ImageServer")!)
        
        // create a raster layer
        self.rasterLayer = AGSRasterLayer(raster: imageServiceRaster)
        
        //initialize a map with dark canvas vector basemap
        self.map = AGSMap(basemap: AGSBasemap.darkGrayCanvasVector())
        
        //add raster layer as an operational layer to the map
        self.map.operationalLayers.add(self.rasterLayer)
        
        //assign the map to the map view
        self.mapView.map = self.map
        
        //set map view's viewpoint to the raster layer's full extent
        self.rasterLayer.load { [weak self] (error) in
            
            guard error == nil else {
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
                return
            }
            
            if let center = self?.rasterLayer.fullExtent?.center {
                self?.mapView.setViewpoint(AGSViewpoint(center: center, scale: 50000000))
            }
        }
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["RasterLayerUsingServiceVC"]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}



