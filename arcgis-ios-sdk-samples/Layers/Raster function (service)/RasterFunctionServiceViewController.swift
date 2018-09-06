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

class RasterFunctionServiceViewController: UIViewController {
    
    @IBOutlet private weak var mapView: AGSMapView!
    private var map: AGSMap?
    private var imageServiceRaster: AGSImageServiceRaster?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["RasterFunctionServiceViewController"]
        
        // Initialize map and set it on map view
        map = AGSMap(basemap: .darkGrayCanvasVector())
        mapView.map = map
        
        // Initialize image service raster and apply raster function when it's loaded
        imageServiceRaster = AGSImageServiceRaster(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/NLCDLandCover2001/ImageServer")!)
        imageServiceRaster?.load { [weak self] (error) in
            guard error == nil else {
                SVProgressHUD.show(withStatus: error!.localizedDescription)
                return
            }
            
            // Set map view's viewpoint to the image service raster's full extent
            if let center = self?.imageServiceRaster?.serviceInfo?.fullExtent?.center {
                self?.mapView.setViewpoint(AGSViewpoint(center: center, scale: 58000000.0))
            }
            
            // Apply raster function
            self?.applyRasterFunction()
        }
        
    }
    
    func applyRasterFunction() {
        //
        // NOTE: This is the ASCII text for actual raw JSON string:
        // ========================================================
        //{
        //  "raster_function_arguments":
        //  {
        //    "z_factor":{"double":25.0,"type":"Raster_function_variable"},
        //    "slope_type":{"raster_slope_type":"none","type":"Raster_function_variable"},
        //    "azimuth":{"double":315,"type":"Raster_function_variable"},
        //    "altitude":{"double":45,"type":"Raster_function_variable"},
        //    "type":"Raster_function_arguments",
        //    "raster":{"name":"raster","is_raster":true,"type":"Raster_function_variable"},
        //    "nbits":{"int":8,"type":"Raster_function_variable"}
        //  },
        //  "raster_function":{"type":"Hillshade_function"},
        //  "type":"Raster_function_template"
        //}
        
        // Define the JSON string needed for the raster function
        let rasterFunctionJSONString = "{" +
            "\"raster_function_arguments\":" +
            "{" +
            "    \"z_factor\":{\"double\":25.0,\"type\":\"Raster_function_variable\"}," +
            "    \"slope_type\":{\"raster_slope_type\":\"none\",\"type\":\"Raster_function_variable\"}," +
            "    \"azimuth\":{\"double\":315,\"type\":\"Raster_function_variable\"}," +
            "    \"altitude\":{\"double\":45,\"type\":\"Raster_function_variable\"}," +
            "    \"type\":\"Raster_function_arguments\"," +
            "    \"raster\":{\"name\":\"raster\",\"is_raster\":true,\"type\":\"Raster_function_variable\"}," +
            "    \"nbits\":{\"int\":8,\"type\":\"Raster_function_variable\"}" +
            "}," +
            "\"raster_function\":{\"type\":\"Hillshade_function\"}," +
            "\"type\":\"Raster_function_template\"" +
        "}"

        // NOTE: You can alternatively create the raster function via a JSON string that is contained in a
        // file on disk (ex: hillshade_simplified.json) via the constructor: AGSRasterFunction(fileURL: <#T##URL#>)
        
        // Create a raster function from the JSON string
        if let rasterFunction = AGSRasterFunction.fromJSON(rasterFunctionJSONString, error: nil) as? AGSRasterFunction {
            if let imageServiceRaster = imageServiceRaster {
                //
                // Get the raster function arguments
                let rasterFunctionArguments = rasterFunction.arguments
                
                // Get first raster name from raster function arguments
                let rasterName = rasterFunctionArguments?.rasterNames[0]
                
                // Set image service raster in the raster function arguments with name
                rasterFunctionArguments?.setRaster(imageServiceRaster, withName: rasterName!)
                
                // Create new raster with raster function
                let raster = AGSRaster(rasterFunction: rasterFunction)
                
                // Create a new raster layer from the raster
                let rasterLayer = AGSRasterLayer(raster: raster)
                
                // Add raster layer as operational layer
                map?.operationalLayers.add(rasterLayer)
            }
        }
    }
}
