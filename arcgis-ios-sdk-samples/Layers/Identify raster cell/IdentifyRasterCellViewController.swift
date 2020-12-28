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
            mapView.setViewpoint(AGSViewpoint(latitude: -34.1, longitude: 18.6, scale: 1155581.108577))
            mapView.touchDelegate = self
            mapView.callout.customView = calloutStackView
            mapView.callout.isAccessoryButtonHidden = true
        }
    }
    
    // MARK: Properties
    
    /// The raster layer created using local raster file.
    let rasterLayer = AGSRasterLayer(raster: AGSRaster(name: "SA_EVI_8Day_03May20", extension: "tif"))
    
    /// A formatter for coordinates.
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3
        return formatter
    }()
    
    // MARK: Initialize map and identify pixel
    
    /// Create a map.
    ///
    /// - Returns: An `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemapStyle: .arcGISOceans)
        map.operationalLayers.add(rasterLayer)
        return map
    }
    
    /// Identify a pixel on the raster layer and display the result in a callout.
    ///
    /// - Parameters:
    ///   - screenPoint: The point at which to identify features.
    ///   - offset: An offset to the point where the callout is displayed.
    func identifyPixel(at screenPoint: CGPoint, offset: CGPoint = .zero) {
        mapView.identifyLayer(rasterLayer, screenPoint: screenPoint, tolerance: 1.0, returnPopupsOnly: false) { [weak self] identifyResult in
            guard let self = self else { return }
            if identifyResult.geoElements.isEmpty {
                // If there are no geo elements identified, e.g. not on a raster layer, dismiss the callout.
                self.mapView.callout.dismiss()
                return
            }
            guard let cell = identifyResult.geoElements.first(where: { $0 is AGSRasterCell }) else {
                return
            }
            let calloutText = cell.attributes.map { "\($0.key): \($0.value)" }.joined(separator: "\n")
            let extent = cell.geometry!.extent
            let xyCoordinates = """
            X: \(self.formatter.string(from: extent.xMin as NSNumber)!)
            Y: \(self.formatter.string(from: extent.yMin as NSNumber)!)
            """
            self.calloutStackView.attributesLabel.text = calloutText
            self.calloutStackView.coordinatesLabel.text = xyCoordinates
            self.mapView.callout.show(
                at: self.mapView.screen(toLocation: screenPoint),
                screenOffset: offset,
                rotateOffsetWithMap: false,
                animated: false
            )
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["IdentifyRasterCellViewController"]
        // Load the raster layer.
        rasterLayer.load { [weak self] (error) in
            if let error = error {
                self?.presentAlert(error: error)
            }
        }
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension IdentifyRasterCellViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Tap to identify a pixel on the raster layer.
        identifyPixel(at: screenPoint)
    }
    
    func geoView(_ geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Show the callout with offset so that the finger does not cover the callout.
        identifyPixel(at: screenPoint, offset: CGPoint(x: 0, y: -70))
    }
    
    func geoView(_ geoView: AGSGeoView, didMoveLongPressToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        identifyPixel(at: screenPoint, offset: CGPoint(x: 0, y: -70))
    }
    
    func geoView(_ geoView: AGSGeoView, didEndLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // When tap drag finishes, show the callout without offset.
        identifyPixel(at: screenPoint)
    }
}

// MARK: - Custom stack view to show in a callout

class IdentifyRasterCellStackView: UIStackView {
    @IBOutlet weak var attributesLabel: UILabel!
    @IBOutlet weak var coordinatesLabel: UILabel!
}
