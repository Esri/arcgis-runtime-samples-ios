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

protocol MissionSettingsVCDelegate: AnyObject {
    func missionSettingsViewController(_ missionSettingsViewController: MissionSettingsViewController, didSelectMissionAtIndex index: Int)
    func missionSettingsViewController(_ missionSettingsViewController: MissionSettingsViewController, didChangeSpeed speed: Int)
}

class MissionSettingsViewController: UITableViewController {
    @IBOutlet private weak var missionCell: UITableViewCell?
    @IBOutlet private weak var speedSlider: UISlider?
    @IBOutlet private weak var progressView: UIProgressView?
    
    weak var delegate: MissionSettingsVCDelegate?
    
    var missionFileNames: [String] = []
    var selectedMissionIndex: Int = 0 {
        didSet {
            updateMissionCell()
        }
    }
    var animationSpeed = 50
    var progress: Float = 0 {
        didSet {
            updateProgressViewForProgress()
        }
    }
    
    private func updateProgressViewForProgress() {
        progressView?.progress = progress
    }
    
    private func updateMissionCell() {
        if selectedMissionIndex < missionFileNames.count {
            missionCell?.detailTextLabel?.text = missionFileNames[selectedMissionIndex]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateMissionCell()
        
        speedSlider?.value = Float(animationSpeed)
        updateProgressViewForProgress()
    }
    
    // MARK: - Actions
    
    @IBAction func speedValueChanged(_ sender: UISlider) {
        animationSpeed = Int(sender.value)
        delegate?.missionSettingsViewController(self, didChangeSpeed: Int(sender.value))
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.cellForRow(at: indexPath) == missionCell {
            let controller = OptionsTableViewController(labels: missionFileNames, selectedIndex: selectedMissionIndex) { (newIndex) in
                self.selectedMissionIndex = newIndex
                self.delegate?.missionSettingsViewController(self, didSelectMissionAtIndex: newIndex)
            }
            controller.title = "Mission"
            show(controller, sender: self)
        }
    }
}
