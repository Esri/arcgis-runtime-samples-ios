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

import UIKit
import ArcGIS

class BlendRendererViewController: UIViewController, BlendRendererSettingsVCDelegate {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var visualEffectView: UIVisualEffectView!
    
    private var map:AGSMap!
    
    private var rasterLayer: AGSRasterLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["BlendRendererViewController", "BlendRendererSettingsVC"]
        
        //create a raster
        let raster = AGSRaster(name: "Shasta", extension: "tif")
        
        //create raster layer using raster
        self.rasterLayer = AGSRasterLayer(raster: raster)
        
        //initialize map with raster layer as the basemap
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: self.rasterLayer))
        
        //assign map to the map view
        self.mapView.map = self.map
    }
    
    private func generateBlendRenderer(altitude: Double, azimuth: Double, slopeType: AGSSlopeType, colorRampType: AGSPresetColorRampType) -> AGSBlendRenderer {
        
        //create the raster to be used as elevation raster
        let raster = AGSRaster(name: "Shasta_Elevation", extension: "tif")
        
        //create a colorRamp object from the type specified
        let colorRmp = AGSColorRamp(type: colorRampType, size: 800)
        
        //create a blend renderer
        let renderer = AGSBlendRenderer(elevationRaster: raster, outputMinValues: [9], outputMaxValues: [255], sourceMinValues: [], sourceMaxValues: [], noDataValues: [], gammas: [], colorRamp: colorRmp, altitude: altitude, azimuth: azimuth, zFactor: 1, slopeType: slopeType, pixelSizeFactor: 1, pixelSizePower: 1, outputBitDepth: 8)
        
        return renderer
    }

    //MARK: - BlendRendererSettingsVCDelegate
    
    func blendRendererSettingsVC(_ blendRendererSettingsVC: BlendRendererSettingsVC, selectedAltitude altitude: Double, azimuth: Double, slopeType: AGSSlopeType, colorRampType: AGSPresetColorRampType) {
        
        //get the blend render for the specified settings
        let blendRenderer = self.generateBlendRenderer(altitude: altitude, azimuth: azimuth, slopeType: slopeType, colorRampType: colorRampType)
        
        //if the colorRamp type is None, then use the Shasta.tif for blending.
        //else use the elevation raster with color ramp
        var baseRaster:AGSRaster
        if colorRampType == .none {
            baseRaster = AGSRaster(name: "Shasta", extension: "tif")
        }
        else {
            baseRaster = AGSRaster(name: "Shasta_Elevation", extension: "tif")
        }
        
        //create a raster layer with the new raster
        self.rasterLayer = AGSRasterLayer(raster: baseRaster)
        
        //add the raster layer as the basemap
        self.mapView.map?.basemap = AGSBasemap(baseLayer: self.rasterLayer)

        //apply the blend renderer on this new raster layer
        self.rasterLayer.renderer = blendRenderer
        
        self.hideVisualEffectView()
    }
    
    //MARK: - Actions
    
    func hideVisualEffectView() {
        self.visualEffectView.isHidden = true
    }
    
    @IBAction func editRendererAction() {
        //show visual effect view
        self.visualEffectView.isHidden = false
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SettingsEmbedSegue" {
            let controller = segue.destination as! BlendRendererSettingsVC
            controller.delegate = self
        }
    }
}
