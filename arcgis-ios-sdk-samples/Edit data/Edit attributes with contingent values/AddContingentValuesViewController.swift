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
    @IBOutlet var doneBarButtonItem: UIBarButtonItem!
    
    // MARK: Actions
    
    @IBAction func cancelBarButtonItemTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func doneBarButtonItemTapped(_ sender: Any) {
        
        dismiss(animated: true)
    }
    
    // MARK: Properties
    
    var featureTable: AGSArcGISFeatureTable?
    
    var selectedActivity: AGSCodedValue? {
        didSet {
            if let codedValueName = selectedActivity?.name {
                editRightDetail(cell: activityCell, codedValueName: codedValueName)
                protectionCell.textLabel?.isEnabled = true
            }
        }
    }
    
    var selectedProtection: AGSContingentCodedValue? {
        didSet {
            if let codedValueName = selectedProtection?.codedValue.name {
                editRightDetail(cell: protectionCell, codedValueName: codedValueName)
                bufferSizeCell.textLabel?.isEnabled = true
            }
        }
    }
    
    var selectedBufferSize: AGSContingentCodedValue? {
        didSet {
            if let codedValueName = selectedBufferSize?.codedValue.name {
                editRightDetail(cell: bufferSizeCell, codedValueName: codedValueName)
                doneBarButtonItem.isEnabled = true
            }
        }
    }
    
    // MARK: Functions
    
    func showActivityOptions() {
        guard let featureTable = featureTable else { return }
//        let contingentValuesDefinition = featureTable.contingentValuesDefinition
        let activityField = featureTable.field(forName: "Activity")
        let codedValueDomain = activityField?.domain as! AGSCodedValueDomain
        let activityOptions = codedValueDomain.codedValues
        let selectedIndex = activityOptions.firstIndex { $0.name == self.selectedActivity?.name} ?? nil
        let optionsViewController = OptionsTableViewController(labels: activityOptions.map { $0.name }, selectedIndex: selectedIndex) { newIndex in
            self.selectedActivity = activityOptions[newIndex]
            self.navigationController?.popViewController(animated: true)
        }
        optionsViewController.title = "Activity"
        self.show(optionsViewController, sender: self)
//        contingentValuesDefinition.load { [ weak self] error in
//            guard let self = self else { return}
//            if let feature = featureTable.createFeature() as? AGSArcGISFeature {
//            }
//      }
    }
    
    func showProtectionOptions() {
//        let protectionField = featureTable?.field(forName: "Protection")
//        let codedValueDomain = protectionField?.domain as! AGSCodedValueDomain
//        let protectionOptions = codedValueDomain.codedValues
//        let selectedIndex = protectionOptions.firstIndex { $0.name == self.selectedActivity?.name} ?? nil
//        let optionsViewController = OptionsTableViewController(labels: protectionOptions.map { $0.name }, selectedIndex: selectedIndex) { newIndex in
//            self.selectedProtection = protectionOptions[newIndex]
//            self.navigationController?.popViewController(animated: true)
//        }
//        optionsViewController.title = "Activity"
//        self.show(optionsViewController, sender: self)
        featureTable?.load { [weak self] error in
            guard let self = self else { return }
            let contingentValuesDefinition = self.featureTable?.contingentValuesDefinition
            contingentValuesDefinition?.load { error in
                if let feature = self.featureTable?.createFeature() as? AGSArcGISFeature {
                    let attributes = feature.attributes
                    feature.attributes["Activity"] = self.selectedActivity?.name
                    let contingentValueResult = self.featureTable?.contingentValues(with: feature, field: "Protection")
                    let protectionGroupContingentValues = contingentValueResult?.contingentValuesByFieldGroup["ProtectionFieldGroup"] as? [AGSContingentCodedValue]
                    protectionGroupContingentValues?.forEach { each in
                        print("\(each.codedValue.name)")
                    }
                }
            }
        }
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
