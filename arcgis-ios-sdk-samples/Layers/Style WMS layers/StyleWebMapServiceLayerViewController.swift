//
// Copyright © 2018 Esri.
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
//

import UIKit
import ArcGIS

/// A view controller that manages the interface of the Style WMS Layers sample.
class StyleWebMapServiceLayerViewController: UIViewController {
    /// The map displayed in the map view.
    let map: AGSMap
    let layer: AGSWMSLayer
    var styles = [String]()
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    required init?(coder aDecoder: NSCoder) {
        // Create the map.
        map = AGSMap()
        
        // Create the WMS layer and add it to the map.
        layer = AGSWMSLayer(
            url: URL(string: "http://geoint.lmic.state.mn.us/cgi-bin/wms?VERSION=1.3.0&SERVICE=WMS&REQUEST=GetCapabilities")!,
            layerNames: ["fsa2017"]
        )
        map.operationalLayers.add(layer)
        
        super.init(coder: aDecoder)
        
        // Load the WMS layer.
        layer.load { [weak self] (error) in
            if let error = error {
                self?.layerDidFailToLoad(with: error)
            } else {
                self?.layerDidLoad()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["StyleWebMapServiceLayerViewController"]
        
        // Assign the map to the map view.
        mapView.map = map
        
        // The segmented control needs to be enabled here if the layer is
        // already loaded.
        updateSegmentedControlEnabledState()
    }
    
    /// Called in response to the layer loading successfully.
    func layerDidLoad() {
        guard let sublayer = layer.sublayers.firstObject as? AGSWMSSublayer else {
            return
        }
        styles = sublayer.sublayerInfo.styles
        // The segmented control needs to be enabled here if the view is already
        // loaded.
        updateSegmentedControlEnabledState()
    }
    
    /// Called in response to the layer failing to load. Presents an alert
    /// announcing the failure.
    ///
    /// - Parameter error: The error that caused loading to fail.
    func layerDidFailToLoad(with error: Error) {
        let alertController = UIAlertController(title: nil, message: "Failed to load WMS layer", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okayAction)
        alertController.preferredAction = okayAction
        present(alertController, animated: true)
    }
    
    /// Sets the enabled state of the segmented control based on whether there
    /// are multiple styles.
    func updateSegmentedControlEnabledState() {
        segmentedControl?.isEnabled = styles.count > 1
    }
    
    @IBAction func changeStyle(_ sender: UISegmentedControl) {
        let sublayer = layer.sublayers.firstObject as? AGSWMSSublayer
        sublayer?.currentStyle = styles[sender.selectedSegmentIndex]
    }
}
