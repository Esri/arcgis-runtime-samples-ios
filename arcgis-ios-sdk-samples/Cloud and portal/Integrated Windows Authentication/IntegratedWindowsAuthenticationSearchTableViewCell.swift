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

/// A table view cell whose text label text color matches its tint color.
class IntegratedWindowsAuthenticationButtonTableViewCell: UITableViewCell {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        accessibilityTraits.insert(.button)
    }
    
    /// Updates the text color of the text label to match the tint color of the
    /// cell.
    private func updateTextLabelAppearance() {
        textLabel?.textColor = tintColor
    }
    
    // MARK: UIView
    
    override var isUserInteractionEnabled: Bool {
        didSet {
            if isUserInteractionEnabled {
                tintAdjustmentMode = .automatic
                accessibilityTraits.remove(.notEnabled)
            } else {
                tintAdjustmentMode = .dimmed
                accessibilityTraits.insert(.notEnabled)
            }
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateTextLabelAppearance()
    }
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        updateTextLabelAppearance()
    }
}
