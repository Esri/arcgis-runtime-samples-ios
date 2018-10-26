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

class RGBRendererInputCell: UITableViewCell {
    
    @IBOutlet weak var leadingLabel: UILabel!
    @IBOutlet weak var textField: UITextField!
    
    let numberFormatter = NumberFormatter()
    
    func update(for value: Double) {
        textField.text = numberFormatter.string(from: value as NSNumber)
    }
    
}

class RGBRenderer3InputCell: UITableViewCell {

    @IBOutlet weak var leadingLabel: UILabel!
    @IBOutlet weak var textField1: UITextField!
    @IBOutlet weak var textField2: UITextField!
    @IBOutlet weak var textField3: UITextField!
    
    let numberFormatter = NumberFormatter()
    
    func update(for values: [Double]) {
        if values.count >= 3 {
            textField1.text = numberFormatter.string(from: values[0] as NSNumber)
            textField2.text = numberFormatter.string(from: values[1] as NSNumber)
            textField3.text = numberFormatter.string(from: values[2] as NSNumber)
        }
    }

}
