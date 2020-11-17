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

class RGBRendererViewController: UIViewController, RGBRendererSettingsViewControllerDelegate {
    @IBOutlet var mapView: AGSMapView!
    
    private var rasterLayer: AGSRasterLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["RGBRendererViewController", "RGBRendererSettingsViewController", "OptionsTableViewController"]

        //create raster
        let raster = AGSRaster(name: "Shasta", extension: "tif")
        
        //create raster layer using the raster
        let rasterLayer = AGSRasterLayer(raster: raster)
        self.rasterLayer = rasterLayer
        
        //initialize a map with raster layer as the basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: rasterLayer))
        //assign map to the map view
        mapView.map = map
    }
    
    // MARK: - RGBRendererSettingsViewControllerDelegate
    
    func rgbRendererSettingsViewController(_ rgbRendererSettingsViewController: RGBRendererSettingsViewController, didSelectStretchParameters parameters: AGSStretchParameters) {
        let renderer = AGSRGBRenderer(stretchParameters: parameters, bandIndexes: [], gammas: [], estimateStatistics: true)
        rasterLayer?.renderer = renderer
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? RGBRendererSettingsViewController {
            controller.preferredContentSize = CGSize(width: 375, height: 135)
            controller.delegate = self
            if let parameters = (rasterLayer?.renderer as? AGSRGBRenderer)?.stretchParameters {
                controller.setupForParameters(parameters)
            }
            navController.presentationController?.delegate = self
        }
    }
}

extension RGBRendererViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
