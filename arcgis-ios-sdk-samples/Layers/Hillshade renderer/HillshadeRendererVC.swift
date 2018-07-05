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

class HillshadeRendererVC: UIViewController, HillshadeSettingsDelegate {
    
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var visualEffectView: UIVisualEffectView!
    
    var map:AGSMap!
    
    var rasterLayer: AGSRasterLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["HillshadeRendererVC", "HillshadeSettingsVC"]
        
        let raster = AGSRaster(name: "srtm", extension: "tiff")
        self.rasterLayer = AGSRasterLayer(raster: raster)
        
        self.map = AGSMap(basemap: AGSBasemap(baseLayer: self.rasterLayer))
        
        self.mapView.map = self.map
        
        //initial renderer
        let renderer = AGSHillshadeRenderer(altitude: 45, azimuth: 315, zFactor: 0.000016, slopeType: .none, pixelSizeFactor: 1, pixelSizePower: 1, outputBitDepth: 8)
        rasterLayer.renderer = renderer
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SettingsEmbedSegue" {
            let controller = segue.destination as! HillshadeSettingsVC
            controller.delegate = self
        }
    }
    
    //MARK: - Actions
    
    func hideVisualEffectView() {
        self.visualEffectView.isHidden = true
    }
    
    @IBAction func editRendererAction() {
        //show visual effect view
        self.visualEffectView.isHidden = false
    }
    
    //MARK: - HillshadeSettingsDelegate
    
    func hillshadeSettingsVC(_ hillshadeSettingsVC: HillshadeSettingsVC, selectedAltitude altitude: Double, azimuth: Double, slopeType: AGSSlopeType) {
        
        //hide settings view
        self.hideVisualEffectView()
        
        let renderer = AGSHillshadeRenderer(altitude: altitude, azimuth: azimuth, zFactor: 0.000016, slopeType: slopeType, pixelSizeFactor: 1, pixelSizePower: 1, outputBitDepth: 8)
        self.rasterLayer.renderer = renderer
    }
}

