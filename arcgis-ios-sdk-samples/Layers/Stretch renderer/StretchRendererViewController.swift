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

class StretchRendererViewController: UIViewController, StretchRendererSettingsVCDelegate {
    @IBOutlet var mapView: AGSMapView!
    
    private weak var rasterLayer: AGSRasterLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["StretchRendererViewController", "StretchRendererSettingsVC", "StretchRendererInputCell", "OptionsTableViewController"]
        
        //create raster
        let raster = AGSRaster(name: "ShastaBW", extension: "tif")
        
        //create raster layer using the raster
        let rasterLayer = AGSRasterLayer(raster: raster)
        self.rasterLayer = rasterLayer
        
        //initialize a map with raster layer as the basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: rasterLayer))
        //assign map to the map view
        mapView.map = map
    }
    
    // MARK: - StretchRendererSettingsVCDelegate
    
    func stretchRendererSettingsVC(_ stretchRendererSettingsVC: StretchRendererSettingsVC, didSelectStretchParameters parameters: AGSStretchParameters) {
        let renderer = AGSStretchRenderer(stretchParameters: parameters, gammas: [], estimateStatistics: true, colorRamp: AGSColorRamp(type: .none, size: 1))
        rasterLayer?.renderer = renderer
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? StretchRendererSettingsVC {
            controller.delegate = self
            controller.preferredContentSize = {
                let height: CGFloat
                if traitCollection.horizontalSizeClass == .regular,
                    traitCollection.verticalSizeClass == .regular {
                    height = 200
                } else {
                    height = 150
                }
                return CGSize(width: 375, height: height)
            }()
            navController.presentationController?.delegate = self
        }
    }
}

extension StretchRendererViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
