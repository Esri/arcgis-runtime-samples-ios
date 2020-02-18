// Copyright 2020 Esri.
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

class DisplaySubtypeSettingsViewController: UITableViewController {
    /// The map whose settings should be adjusted.
    var map: AGSMap!
    /// The scale of the map. The default it `0`.
    var mapScale = 0.0
    /// The delegate of the view controller.
    weak var delegate: MapReferenceScaleSettingsViewControllerDelegate?

    
    @IBOutlet weak var referenceScaleLabel: UILabel!
    @IBOutlet weak var referenceScalePickerView: UIPickerView!
}
