//
// Copyright 2016 Esri.
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

protocol StretchRendererTypeCellDelegate: AnyObject {
    
    func stretchRendererTypeCell(_ stretchRendererTypeCell: StretchRendererTypeCell, didUpdateType type: StretchType)
}

class StretchRendererTypeCell: UITableViewCell, HorizontalPickerDelegate {
    
    @IBOutlet var horizontalPicker: HorizontalPicker!
    
    weak var delegate: StretchRendererTypeCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.horizontalPicker.options = StretchType.allValues
        self.horizontalPicker.delegate = self
    }
    
    //MARK: - HorizontalPickerDelegate
    
    func horizontalPicker(_ horizontalPicker: HorizontalPicker, didUpdateSelectedIndex index: Int) {
        self.delegate?.stretchRendererTypeCell(self, didUpdateType: StretchType(id: index)!)
    }
    
}
