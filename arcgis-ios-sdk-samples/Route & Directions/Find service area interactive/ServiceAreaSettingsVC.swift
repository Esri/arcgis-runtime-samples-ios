//
// Copyright 2017 Esri.
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

protocol ServiceAreaSettingsVCDelegate:class {
    
    func serviceAreaSettingsVC(_ serviceAreaSettingsVC:ServiceAreaSettingsVC, didUpdateFirstTimeBreak timeBreak:Int)
    
    func serviceAreaSettingsVC(_ serviceAreaSettingsVC:ServiceAreaSettingsVC, didUpdateSecondTimeBreak timeBreak:Int)
}

class ServiceAreaSettingsVC: UIViewController {

    @IBOutlet private var firstTimeBreakSlider:UISlider!
    @IBOutlet private var secondTimeBreakSlider:UISlider!
    @IBOutlet private var firstTimeBreakLabel:UILabel!
    @IBOutlet private var secondTimeBreakLabel:UILabel!
    
    weak var delegate:ServiceAreaSettingsVCDelegate?
    
    var firstTimeBreak:Int = 3
    var secondTimeBreak:Int = 8
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.firstTimeBreakLabel.text = "\(self.firstTimeBreak)"
        self.secondTimeBreakLabel.text = "\(self.secondTimeBreak)"
        
        self.firstTimeBreakSlider.value = Float(self.firstTimeBreak)
        self.secondTimeBreakSlider.value = Float(self.secondTimeBreak)
    }
    
    //MARK: - Actions
    
    @IBAction private func sliderValueChanged(sender:UISlider) {
        
        if sender == self.firstTimeBreakSlider {
            
            self.firstTimeBreakLabel.text = "\(Int(sender.value))"
            
            self.delegate?.serviceAreaSettingsVC(self, didUpdateFirstTimeBreak: Int(sender.value))
        }
        else {
            
            self.secondTimeBreakLabel.text = "\(Int(sender.value))"
            
            self.delegate?.serviceAreaSettingsVC(self, didUpdateSecondTimeBreak: Int(sender.value))
        }
    }

}
