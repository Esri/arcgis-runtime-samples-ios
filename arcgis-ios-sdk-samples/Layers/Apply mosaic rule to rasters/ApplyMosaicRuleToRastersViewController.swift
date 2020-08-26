// Copyright 2020 Esri
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

class ApplyMosaicRuleToRastersViewController: UIViewController {
    // MARK: Storyboard views and instance properties
    
    /// A label to show status messages.
    @IBOutlet weak var statusLabel: UILabel!
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    /// The image service raster to demo mosaic rules.
    var imageServiceRaster: AGSImageServiceRaster!
    
    let mosaicRulePresets: KeyValuePairs<String, AGSMosaicRule> = {
        // A default mosaic rule object, with mosaic method as none.
        let noneRule = AGSMosaicRule()
        noneRule.mosaicMethod = .none
        
        // A mosaic rule object with northwest method.
        let northWestRule = AGSMosaicRule()
        northWestRule.mosaicMethod = .northwest
        northWestRule.mosaicOperation = .first
        
        // A mosaic rule object with center method and blend operation.
        let centerRule = AGSMosaicRule()
        centerRule.mosaicMethod = .center
        centerRule.mosaicOperation = .blend
        
        // A mosaic rule object with byAttribute method and sort on "OBJECTID" field of the service.
        let byAttributeRule = AGSMosaicRule()
        byAttributeRule.mosaicMethod = .attribute
        byAttributeRule.sortField = "OBJECTID"
        
        // A mosaic rule object with lockRaster method and locks 3 image rasters.
        let lockRasterRule = AGSMosaicRule()
        lockRasterRule.mosaicMethod = .lockRaster
        lockRasterRule.lockRasterIDs = [1, 7, 12]
        
        return ["None": noneRule,
                "NorthWest": northWestRule,
                "Center": centerRule,
                "ByAttribute": byAttributeRule,
                "LockRaster": lockRasterRule]
    }()
    
    // MARK: Instance methods
    
    /// Create a map.
    ///
    /// - Returns: An `AGSMap` object.
    func makeMap() -> AGSMap {
        // The URL of an image service that supports mosaic rules.
        let imageServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/amberg_germany/ImageServer")!
        // Create an image service raster from an online raster service.
        imageServiceRaster = AGSImageServiceRaster(url: imageServiceURL)
        // Check if a mosaic rule exists. If not, create one.
        if imageServiceRaster.mosaicRule == nil {
            imageServiceRaster.mosaicRule = AGSMosaicRule()
        }
        // Create a raster layer.
        let rasterLayer = AGSRasterLayer(raster: imageServiceRaster)
        let map = AGSMap(basemap: .topographicVector())
        // Add raster layer as an operational layer to the map.
        map.operationalLayers.add(rasterLayer)
        rasterLayer.load { [weak self] (error: Error?) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // When loaded, set map view's viewpoint to the image service raster's center.
                if let center = self.imageServiceRaster.serviceInfo?.fullExtent?.center {
                    self.mapView.setViewpoint(AGSViewpoint(center: center, scale: 25000.0))
                }
                self.setStatus(message: "Image service raster loaded.")
            }
        }
        return map
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    // MARK: Actions
    
    @IBAction func chooseMosaicRule(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Choose a mosaic rule to apply to the image service.",
            message: nil,
            preferredStyle: .actionSheet
        )
        mosaicRulePresets.forEach { name, rule in
            let action = UIAlertAction(title: name, style: .default) { _ in
                self.setStatus(message: "\(name) selected.")
                self.imageServiceRaster.mosaicRule = rule
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = sender
        present(alertController, animated: true)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["ApplyMosaicRuleToRastersViewController"]
    }
}
