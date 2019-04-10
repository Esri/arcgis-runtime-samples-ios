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

protocol HotspotSettingsVCDelegate: AnyObject {
    func hotspotSettingsViewController(_ hotspotSettingsViewController: HotspotSettingsViewController, didSelectDates fromDate: Date, toDate: Date)
}

class HotspotSettingsViewController: UITableViewController {
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    
    weak var delegate: HotspotSettingsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDatePickerLimits()
    }
    
    /// Set the date picker limits to maintain a valid state.
    private func updateDatePickerLimits() {
        // keep the start date less than the end date
        startDatePicker.maximumDate = Calendar.current.date(byAdding: .day, value: -1, to: endDatePicker.date)
        // keep the end date greater than the start date
        endDatePicker.minimumDate = Calendar.current.date(byAdding: .day, value: 1, to: startDatePicker.date)
    }
    
    // MARK: - Actions
    
    @IBAction func datePickerAction(_ sender: Any) {
        updateDatePickerLimits()
    }
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func analyzeAction() {
        delegate?.hotspotSettingsViewController(self, didSelectDates: startDatePicker.date, toDate: endDatePicker.date)
    }
}
