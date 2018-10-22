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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialize a map with dark canvas vector basemap
        let map = AGSMap(basemap: .darkGrayCanvasVector())
        
        // assign the map to the map view
        mapView.map = map
        
        // set the viewpoint to the Golden Gate of the San Francisco Bay
        let center = AGSPoint(x: -13637000, y: 4550000, spatialReference: .webMercator())
        mapView.setViewpointCenter(center, scale: 100000)
        
        /// The URL of an image service containing a bathymetric attributed grid.
        let imageServiceURL = URL(string: "https://gis.ngdc.noaa.gov/arcgis/rest/services/bag_hillshades/ImageServer")!
        // create an image service raster from an online raster service
        let imageServiceRaster = AGSImageServiceRaster(url: imageServiceURL)
        // create a raster layer
        let rasterLayer = AGSRasterLayer(raster: imageServiceRaster)
        
        // add raster layer as an operational layer to the map
        map.operationalLayers.add(rasterLayer)
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["RasterLayerUsingServiceVC"]
    }
}
