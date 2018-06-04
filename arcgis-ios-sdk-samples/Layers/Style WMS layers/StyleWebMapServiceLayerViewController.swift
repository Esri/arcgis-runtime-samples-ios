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

class StyleWebMapServiceLayerViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBAction func changeStyle(_ sender: UISegmentedControl) {
        guard let sublayer = layer.sublayers.firstObject as? AGSWMSSublayer else {
            preconditionFailure()
        }
        sublayer.currentStyle = styles[sender.selectedSegmentIndex]
    }
    
    let map = AGSMap()
    let layer: AGSWMSLayer = {
        let layerURL = URL(string: "http://geoint.lmic.state.mn.us/cgi-bin/wms?VERSION=1.3.0&SERVICE=WMS&REQUEST=GetCapabilities")!
        let layerNames = ["fsa2017"]
        return AGSWMSLayer(url: layerURL, layerNames: layerNames)
    }()
    var styles = [String]()
    
    /// Enables the segmented control if the view has loaded and there is more
    /// than one style.
    func enableSegmentedControlIfPosasible() {
        guard isViewLoaded, styles.count > 1 else { return }
        segmentedControl.isEnabled = true
    }
    
    /// Called in response to the layer loading successfully.
    func layerDidLoad() {
        guard let sublayer = layer.sublayers.firstObject as? AGSWMSSublayer else {
            return
        }
        styles = sublayer.sublayerInfo.styles
        enableSegmentedControlIfPosasible()
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
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("init(nibName:bundle:) has not been implemented")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        map.operationalLayers.add(layer)
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
        mapView.map = map
        enableSegmentedControlIfPosasible()
    }
}
