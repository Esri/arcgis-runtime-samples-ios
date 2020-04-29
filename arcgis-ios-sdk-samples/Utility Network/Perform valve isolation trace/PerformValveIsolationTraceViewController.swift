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

class PerformValveIsolationTraceViewController: UIViewController {
    /// a
    @IBOutlet weak var traceButton: UIBarButtonItem!
    /// b
    @IBOutlet weak var categoryButton: UIBarButtonItem!
    @IBOutlet weak var isolationSwitch: UISwitch!
    /// The 3-line label to display navigation status.
    @IBOutlet weak var statusLabel: UILabel!
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: .navigationVector())
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["PerformValveIsolationTraceViewController"]
    }
    
    // Change the visibility of the sublayer.
    @IBAction func isolationSwitchAction(_ sender: UISwitch) {
        let _ = sender.isOn
    }
}
