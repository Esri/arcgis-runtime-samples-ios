//
// Copyright © 2019 Esri.
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

protocol ControlAnnotationSublayerVisibilitySublayerCellDelegate: AnyObject {
    func sublayerCellDidToggleSwitch(_ sublayerCell: ControlAnnotationSublayerVisibilitySublayerCell)
}

/// A `UITableViewCell` subclass that displays a label on the left and a switch
/// on the right.
class ControlAnnotationSublayerVisibilitySublayerCell: UITableViewCell {
    /// The switch displayed as the cell's accessory views. Changes to the
    /// switch's value are reported through the delegate.
    let `switch` = UISwitch()
    weak var delegate: ControlAnnotationSublayerVisibilitySublayerCellDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        `switch`.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        accessoryView = `switch`
    }
    
    @objc
    private func switchValueChanged() {
        delegate?.sublayerCellDidToggleSwitch(self)
    }
}
