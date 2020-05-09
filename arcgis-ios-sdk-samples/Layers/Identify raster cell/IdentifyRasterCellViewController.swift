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

class IdentifyRasterCellViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The custom stack view to show in a callout.
    @IBOutlet weak var calloutStackView: IdentifyRasterCellStackView!
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.touchDelegate = self
        }
    }
    
    /// The raster layer created using local raster file.
    let rasterLayer = AGSRasterLayer(raster: AGSRaster(name: "Shasta", extension: "tif"))
    
    // MARK: Initialize map and utility network
    
    /// Create a map.
    ///
    /// - Parameter layers: The feature layers for the utility network.
    /// - Returns: An `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .oceans())
        map.operationalLayers.add(rasterLayer)
        return map
    }
    
    func identifyPixel(screenPoint: CGPoint) {
        mapView.identifyLayer(rasterLayer, screenPoint: screenPoint, tolerance: 1.0, returnPopupsOnly: false) { [weak self] identifyResult in
            guard let self = self else { return }
            identifyResult.geoElements.filter { $0 is AGSRasterCell }.forEach { cell in
                var calloutText: String = ""
                cell.attributes.forEach { attr in
                    calloutText.append("\(attr.key): \(attr.value)\n")
                }
                let xyCoordinates = "X: \(cell.geometry!.extent.xMin)\nY: \(cell.geometry!.extent.yMin)"
                let customCallout = self.calloutStackView!
                customCallout.attributesLabel.text = calloutText
                customCallout.coordinatesLabel.text = xyCoordinates
                self.mapView.callout.customView = customCallout
                self.mapView.callout.isAccessoryButtonHidden = true
                self.mapView.callout.show(at: self.mapView.screen(toLocation: screenPoint), screenOffset: .zero, rotateOffsetWithMap: false, animated: false)
            }
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["IdentifyRasterCellViewController"]
        // Set map view's viewpoint to the raster layer's full extent
        rasterLayer.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
               self.presentAlert(error: error)
            } else {
                if let center = self.rasterLayer.fullExtent?.center {
                    self.mapView.setViewpoint(AGSViewpoint(center: center, scale: 80000))
                }
            }
        }
    }
}

extension IdentifyRasterCellViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTouchDownAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint, completion: @escaping (Bool) -> Void) {
        // Tell the ArcGIS Runtime if we are going to handle interaction.
        completion(true)
    }
    
    func geoView(_ geoView: AGSGeoView, didTouchUpAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        identifyPixel(screenPoint: screenPoint)
    }
    
    func geoView(_ geoView: AGSGeoView, didTouchDragToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        let offset = CGFloat(50)
        identifyPixel(screenPoint: CGPoint(x: screenPoint.x, y: screenPoint.y - offset))
    }
}
