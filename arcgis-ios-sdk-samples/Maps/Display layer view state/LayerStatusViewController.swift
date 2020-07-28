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
    // MARK: Instance properties
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: .topographic())
            mapView.setViewpoint(AGSViewpoint(center: AGSPoint(x: -11e6, y: 45e5, spatialReference: .webMercator()), scale: 4e7))
            mapView.layerViewStateChangedHandler = layerViewStateChangedHandler
        }
    }
    /// The label to display layer view status.
    @IBOutlet weak var statusLabel: UILabel!
    /// The feature layer loaded from a portal item.
    var featureLayer: AGSFeatureLayer = {
        let portalItem = AGSPortalItem(url: URL(string: "https://runtime.maps.arcgis.com/home/item.html?id=b8f4033069f141729ffb298b7418b653")!)!
        let featureLayer = AGSFeatureLayer(item: portalItem, layerID: 0)
        featureLayer.minScale = 4e8
        featureLayer.maxScale = 4e7
        return featureLayer
    }()
    
    // MARK: Instance methods
    
    /// Display layer view state and handle errors.
    ///
    /// - Parameters:
    ///   - layer: The `AGSLayer` of which view state has changed.
    ///   - state: The `AGSLayerViewState` that contains changed statuses.
    func layerViewStateChangedHandler(layer: AGSLayer, state: AGSLayerViewState) {
        // Only check the view state of the feature layer.
        guard layer == featureLayer else {
            return
        }
        if let error = state.error {
            DispatchQueue.main.async {
                self.presentAlert(error: error)
            }
        }
        DispatchQueue.main.async {
            self.setStatus(message: self.viewStatusString(state.status))
        }
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
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames  = ["LayerStatusViewController"]
        // Load the feature layer.
        featureLayer.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.mapView.map?.operationalLayers.add(self.featureLayer)
            }
        }
    }
}
