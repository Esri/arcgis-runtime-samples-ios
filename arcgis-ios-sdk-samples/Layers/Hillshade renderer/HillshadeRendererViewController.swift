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

class HillshadeRendererViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView!
    
    private weak var rasterLayer: AGSRasterLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "HillshadeRendererViewController",
            "HillshadeSettingsViewController",
            "OptionsTableViewController"
        ]
        
        let raster = AGSRaster(name: "srtm", extension: "tiff")
        let rasterLayer = AGSRasterLayer(raster: raster)
        self.rasterLayer = rasterLayer
        
        let map = AGSMap(basemap: AGSBasemap(baseLayer: rasterLayer))
        
        mapView.map = map
        
        //initial renderer
        setRenderer(altitude: 45, azimuth: 315, slopeType: .none)
    }
    
    private func setRenderer(altitude: Double, azimuth: Double, slopeType: AGSSlopeType) {
        let renderer = AGSHillshadeRenderer(altitude: altitude, azimuth: azimuth, zFactor: 0.000016, slopeType: slopeType, pixelSizeFactor: 1, pixelSizePower: 1, outputBitDepth: 8)
        rasterLayer?.renderer = renderer
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? HillshadeSettingsViewController,
            let renderer = rasterLayer?.renderer as? AGSHillshadeRenderer {
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
            controller.delegate = self
            controller.altitude = renderer.altitude
            controller.azimuth = renderer.azimuth
            controller.slopeType = renderer.slopeType
        }
    }
}

extension HillshadeRendererViewController: HillshadeSettingsViewControllerDelegate {
    func hillshadeSettingsViewController(_ controller: HillshadeSettingsViewController, selectedAltitude altitude: Double, azimuth: Double, slopeType: AGSSlopeType) {
        setRenderer(altitude: altitude, azimuth: azimuth, slopeType: slopeType)
    }
}

extension HillshadeRendererViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
