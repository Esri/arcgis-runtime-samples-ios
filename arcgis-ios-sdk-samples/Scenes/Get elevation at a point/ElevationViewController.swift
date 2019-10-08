// Copyright 2019 Esri.
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

class ElevationViewController: UIViewController {
    var elevation = Measurement(value: 0, unit: UnitLength.meters) {
        didSet {
            loadViewIfNeeded()
            elevationLabel.text = elevationFormatter.string(from: elevation)
            preferredContentSize = view.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
        }
    }
    
    @IBOutlet private var elevationLabel: UILabel!
    
    private let elevationFormatter = MeasurementFormatter()
}
