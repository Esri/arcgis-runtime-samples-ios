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

class ChangeMapViewBackgroundViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ChangeMapViewBackgroundViewController", "GridSettingsViewController", "ColorPickerViewController"]
        
        //initialize tiled layer
        let tiledLayer = AGSArcGISTiledLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/WorldTimeZones/MapServer")!)

        //initialize map with tiled layer as basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: tiledLayer))
        
        //set initial viewpoint
        let center = AGSPoint(x: 3224786, y: 2661231, spatialReference: .webMercator())
        map.initialViewpoint = AGSViewpoint(center: center, scale: 236663484)

        //assign map to the map view
        mapView.map = map
        
        // create a background grid with default values
        let backgroundGrid = AGSBackgroundGrid(color: .black, gridLineColor: .white, gridLineWidth: 2, gridSize: 32)
        // assign the background grid to the map view
        mapView.backgroundGrid = backgroundGrid
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? GridSettingsViewController {
            controller.backgroundGrid = mapView.backgroundGrid
            
            navController.presentationController?.delegate = self
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
        }
    }
}

extension ChangeMapViewBackgroundViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // ensure that the settings are show in a popover even on small displays
        return .none
    }
}
