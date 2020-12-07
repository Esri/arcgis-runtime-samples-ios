// Copyright 2015 Esri.
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

class LayerStatusViewController: UIViewController {
    // MARK: Instance properties and methods
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap(featureLayer: featureLayer)
            mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -11e6, y: 45e5, spatialReference: .webMercator()), scale: 2e7))
            mapView.layerViewStateChangedHandler = { [weak self] layer, state in
                guard let self = self else { return }
                // Only check the view state of the feature layer.
                guard layer == self.featureLayer else { return }
                DispatchQueue.main.async {
                    if let error = state.error {
                        self.presentAlert(error: error)
                    }
                    self.setStatus(message: self.viewStatusString(state.status))
                }
            }
        }
    }
    
    /// The label to display layer view status.
    @IBOutlet weak var statusLabel: UILabel!
    
    /// The feature layer loaded from a portal item.
    let featureLayer: AGSFeatureLayer = {
        let portalItem = AGSPortalItem(url: URL(string: "https://runtime.maps.arcgis.com/home/item.html?id=b8f4033069f141729ffb298b7418b653")!)!
        let featureLayer = AGSFeatureLayer(item: portalItem, layerID: 0)
        featureLayer.minScale = 1e8
        featureLayer.maxScale = 6e6
        return featureLayer
    }()
    
    /// Create a map with an `AGSFeatureLayer` added to its operational layers.
    ///
    /// - Parameter featureLayer: An `AGSFeatureLayer` object.
    /// - Returns: An `AGSMap` object.
    func makeMap(featureLayer: AGSFeatureLayer) -> AGSMap {
        let map = AGSMap(basemapStyle: .arcGISTopographic)
        map.operationalLayers.add(featureLayer)
        return map
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    /// Get a string for current statuses.
    ///
    /// - Parameter status: An `AGSLayerViewStatus` OptionSet that  indicates the layer's statuses.
    /// - Returns: A comma separated string to represent current statuses.
    func viewStatusString(_ status: AGSLayerViewStatus) -> String {
        var statuses = [String]()
        if status.contains(.active) {
            statuses.append("Active")
        }
        if status.contains(.notVisible) {
            statuses.append("Not Visible")
        }
        if status.contains(.outOfScale) {
            statuses.append("Out of Scale")
        }
        if status.contains(.loading) {
            statuses.append("Loading")
        }
        if status.contains(.error) {
            statuses.append("Error")
        }
        if status.contains(.warning) {
            statuses.append("Warning")
        }
        if !statuses.isEmpty {
            return statuses.joined(separator: ", ")
        } else {
            return "Unknown"
        }
    }
    
    // MARK: Actions
    
    @IBAction func layerVisibilitySwitchValueChanged(_ sender: UISwitch) {
        featureLayer.isVisible = sender.isOn
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["LayerStatusViewController"]
        // Avoid the overlap between the status label and the map content.
        mapView.contentInset.top = 2 * statusLabel.font.lineHeight
    }
}
