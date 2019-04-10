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

class BrowseWFSLayersViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView!
    @IBOutlet weak var browseButton: UIBarButtonItem!
    private var wfsService: AGSWFSService!
    private var wfsServiceInfo: AGSWFSServiceInfo?
    
    // Layer Info for the layer that is currently drawn on map view.
    private var displayedLayerInfo: AGSWFSLayerInfo? {
        let selectedLayerInfo = ((mapView?.map?.operationalLayers.firstObject as? AGSFeatureLayer)?.featureTable as? AGSWFSFeatureTable)?.layerInfo
        return selectedLayerInfo
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize a map with topographic basemap
        let map = AGSMap(basemap: .imagery())
        
        // Assign map to the map view
        mapView.map = map
        
        // A URL to the GetCapabilities endpoint of a WFS service
        let wfsServiceURL = URL(string: "https://dservices2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/services/Seattle_Downtown_Features/WFSServer?service=wfs&request=getcapabilities")!
        
        // Create and load a WFS Service, to access the service information
        self.wfsService = AGSWFSService(url: wfsServiceURL)
        self.wfsService.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(message: "Failed to load WFS layer: \(error.localizedDescription)")
            } else if let serviceInfo = self.wfsService.serviceInfo {
                self.wfsServiceInfo = serviceInfo
                self.browseButton.isEnabled = true
            }
        }
        // Add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "BrowseWFSLayersViewController",
            "WFSLayersTableViewController"
        ]
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? WFSLayersTableViewController {
            controller.mapView = mapView
            controller.allLayerInfos = (self.wfsServiceInfo?.layerInfos)!
            controller.selectedLayerInfo = displayedLayerInfo
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

extension BrowseWFSLayersViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
