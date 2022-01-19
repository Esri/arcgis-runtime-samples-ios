// Copyright 2021 Esri
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

class AddContingentValuesViewController: UITableViewController {
    @IBOutlet var activityCell: UITableViewCell!
    @IBOutlet var protectionCell: UITableViewCell!
    @IBOutlet var bufferSizeCell: UITableViewCell!
    
    // MARK: Actions
    
    @IBAction func cancelBarButtonItemTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func doneBarButtonItemTapped(_ sender: Any) {
        
        dismiss(animated: true)
    }
    
    // MARK: Properties
    
    var selectedActivity: AGSContingentCodedValue? {
        didSet {
            if let codedValueName = selectedActivity?.codedValue.name {
                editRightDetail(cell: activityCell, codedValueName: codedValueName)
            }
        }
    }
    
    var selectedProtection: AGSContingentCodedValue? {
        didSet {
            if let codedValueName = selectedProtection?.codedValue.name {
                editRightDetail(cell: protectionCell, codedValueName: codedValueName)
            }
        }
    }
    
    var selectedBufferSize: AGSContingentCodedValue? {
        didSet {
            if let codedValueName = selectedBufferSize?.codedValue.name {
                editRightDetail(cell: bufferSizeCell, codedValueName: codedValueName)
            }
        }
    }
    
    // MARK: functions
    
    func showActivityOptions() {
        
    }
    
    func showProtectionOptions() {
        
    }
    
    func showBufferSizeOptions() {
        
    }
    
    func editRightDetail(cell: UITableViewCell, codedValueName: String) {
        cell.detailTextLabel?.text = codedValueName
    }
    
    // MARK: UITableViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch cell {
        case activityCell:
            showActivityOptions()
        case protectionCell:
            showProtectionOptions()
        case bufferSizeCell:
            showBufferSizeOptions()
        default:
            return
        }
    }
}
