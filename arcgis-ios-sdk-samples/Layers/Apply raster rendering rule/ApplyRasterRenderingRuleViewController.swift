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

class ApplyRasterRenderingRuleViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    /// The choose rendering rule button.
    @IBOutlet var chooseRenderingRuleBarButtonItem: UIBarButtonItem!
    
    // MARK: Properties and methods
    
    /// An online image service that features Charlotte, North Carolina's downtown area.
    let imageServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/CharlotteLAS/ImageServer")!
    /// A list of rendering rule info supported by the service.
    var rasterRenderingRules = [AGSRenderingRuleInfo]()
    /// A dictionary to cache created raster layers.
    var rasterLayers = [String: AGSRasterLayer]()
    
    /// Create a map.
    ///
    /// - Returns: An `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .streets())
        // Create a raster layer from the raster and add it to the map.
        let imageServiceRaster = AGSImageServiceRaster(url: imageServiceURL)
        map.operationalLayers.add(makeRasterLayer(raster: imageServiceRaster))
        // Load the raster and get a list of rendering rule info supported by the service.
        imageServiceRaster.load { [weak self, unowned imageServiceRaster] error in
            guard let self = self else { return }
            if let serviceInfo = imageServiceRaster.serviceInfo, let extent = serviceInfo.fullExtent {
                self.mapView.setViewpoint(AGSViewpoint(targetExtent: extent), completion: nil)
                self.rasterRenderingRules = serviceInfo.renderingRuleInfos
                self.chooseRenderingRuleBarButtonItem.isEnabled = true
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
        return map
    }
    
    /// Create a raster layer from an image service raster with an optional rendering rule.
    ///
    /// - Parameters:
    ///   - raster: An `AGSImageServiceRaster` object.
    ///   - renderingRule: An optional `AGSRenderingRule` object.
    /// - Returns: An `AGSRasterLayer` object.
    func makeRasterLayer(raster: AGSImageServiceRaster, renderingRule: AGSRenderingRule? = nil) -> AGSRasterLayer {
        raster.renderingRule = renderingRule
        let rasterLayer = AGSRasterLayer(raster: raster)
        return rasterLayer
    }
    
    // MARK: Actions
    
    @IBAction func chooseRenderingRule(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Choose a raster rendering rule to apply to the image service raster.",
            message: nil,
            preferredStyle: .actionSheet
        )
        rasterRenderingRules.forEach { ruleInfo in
            let action = UIAlertAction(title: ruleInfo.name, style: .default) { _ in
                let map = self.mapView.map!
                // Clear all raster layers before adding new one.
                map.operationalLayers.removeAllObjects()
                let rasterLayer: AGSRasterLayer
                if self.rasterLayers[ruleInfo.name] != nil {
                    // Retrieve cached raster layer if it exists.
                    rasterLayer = self.rasterLayers[ruleInfo.name]!
                } else {
                    // Create a new `AGSRenderingRule` object with the chosen rule.
                    let renderingRule = AGSRenderingRule(renderingRuleInfo: ruleInfo)
                    let imageServiceRaster = AGSImageServiceRaster(url: self.imageServiceURL)
                    // Create a new raster layer with the rendering rule.
                    rasterLayer = self.makeRasterLayer(raster: imageServiceRaster, renderingRule: renderingRule)
                    self.rasterLayers[ruleInfo.name] = rasterLayer
                }
                // Add the new raster layer to the map.
                map.operationalLayers.add(rasterLayer)
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
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["ApplyRasterRenderingRuleViewController"]
    }
}
