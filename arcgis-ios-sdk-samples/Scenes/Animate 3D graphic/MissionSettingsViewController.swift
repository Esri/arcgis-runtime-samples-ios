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

protocol MissionSettingsVCDelegate:class {
    
    func missionSettingsViewController(_ missionSettingsViewController:MissionSettingsViewController, didSelectMissionAtIndex index:Int)
    
    func missionSettingsViewController(_ missionSettingsViewController:MissionSettingsViewController, didChangeSpeed speed:Int)
}

class MissionSettingsViewController: UIViewController, HorizontalPickerDelegate {

    @IBOutlet private var horizontalPicker:HorizontalPicker!
    @IBOutlet private var speedSlider:UISlider!
    @IBOutlet private var progressView:UIProgressView!
    
    var missionFileNames:[String]!
    var selectedMissionIndex:Int = 0
    var animationSpeed = 50
    var progress:Float = 0 {
        didSet {
            self.progressView?.progress = progress
        }
    }
    
    weak var delegate:MissionSettingsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //preferred content size
        self.preferredContentSize = CGSize(width: 300, height: 200)
        
        self.horizontalPicker.options = self.missionFileNames
        self.horizontalPicker.selectedIndex = self.selectedMissionIndex
        self.horizontalPicker.delegate = self
        
        self.speedSlider.value = Float(self.animationSpeed)
        self.progressView.progress = self.progress
    }
    
    //MARK: - Actions
    
    @IBAction func speedValueChanged(_ sender: UISlider) {
        
        self.delegate?.missionSettingsViewController(self, didChangeSpeed: Int(sender.value))
    }
    
    //MARK: - HorizontalPickerDelegate
    
    func horizontalPicker(_ horizontalPicker: HorizontalPicker, didUpdateSelectedIndex index: Int) {
        
        self.delegate?.missionSettingsViewController(self, didSelectMissionAtIndex: index)
    }

}
