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
        graphicsOverlay?.graphics.removeLastObject()
        dismiss(animated: true)
    }
    
    @IBAction func doneBarButtonItemTapped(_ sender: Any) {
        
        dismiss(animated: true)
    }
    
    // MARK: Properties
    
    var featureTable: AGSArcGISFeatureTable?
    var contingentValuesDefinition: AGSContingentValuesDefinition?
    var feature: AGSArcGISFeature?
    var bufferSizes: [Int]?
    var graphicsOverlay: AGSGraphicsOverlay?
    
    var selectedActivity: AGSCodedValue? {
        didSet {
            if let codedValueName = selectedActivity?.name {
                editRightDetail(cell: activityCell, rightDetailText: codedValueName)
                protectionCell.textLabel?.isEnabled = true
            }
        }
    }
    
    var selectedProtection: AGSContingentCodedValue? {
        didSet {
            if let codedValueName = selectedProtection?.codedValue.name {
                editRightDetail(cell: protectionCell, rightDetailText: codedValueName)
                bufferSizeCell.textLabel?.isEnabled = true
            }
        }
    }
    
    var selectedBufferSize: Int? {
        didSet {
            if let selectedBufferSize = selectedBufferSize {
                let bufferSize = String(selectedBufferSize)
                editRightDetail(cell: bufferSizeCell, rightDetailText: bufferSize)
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
        let selectedIndex = activityOptions.firstIndex { $0.name == self.selectedActivity?.name } ?? nil
        let optionsViewController = OptionsTableViewController(labels: activityOptions.map { $0.name }, selectedIndex: selectedIndex) { newIndex in
            self.selectedActivity = activityOptions[newIndex]
            self.navigationController?.popViewController(animated: true)
        }
        optionsViewController.title = "Activity"
        self.show(optionsViewController, sender: self)
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
            self.contingentValuesDefinition = self.featureTable?.contingentValuesDefinition
            self.contingentValuesDefinition?.load { error in
                if let feature = self.featureTable?.createFeature() as? AGSArcGISFeature {
                    feature.attributes["Activity"] = self.selectedActivity?.code
                    self.feature = feature
                    let contingentValuesResult = self.featureTable?.contingentValues(with: feature, field: "Protection")
                    guard let protectionGroupContingentValues = contingentValuesResult?.contingentValuesByFieldGroup["ProtectionFieldGroup"] as? [AGSContingentCodedValue] else { return }
                    let selectedIndex = protectionGroupContingentValues.firstIndex { $0.codedValue.name == self.selectedProtection?.codedValue.name} ?? nil
                    let optionsViewController = OptionsTableViewController(labels: protectionGroupContingentValues.map { $0.codedValue.name }, selectedIndex: selectedIndex) { newIndex in
                        self.selectedProtection = protectionGroupContingentValues[newIndex]
                        feature.attributes["Protection"] = self.selectedProtection?.codedValue.code
                        self.navigationController?.popViewController(animated: true)
                    }
                    optionsViewController.title = "Protection"
                    self.show(optionsViewController, sender: self)
                }
            }
        }
    }
    
    func showBufferSizeOptions() {
        guard let feature = feature else { return }
        let contingentValueResult = featureTable?.contingentValues(with: feature, field: "BufferSize")
        guard let bufferSizeGroupContingentValues = contingentValueResult?.contingentValuesByFieldGroup["BufferSizeFieldGroup"] as? [AGSContingentRangeValue] else { return }
        let minValue = bufferSizeGroupContingentValues[0].minValue as! Int
        let maxValue = bufferSizeGroupContingentValues[0].maxValue as! Int
        bufferSizes = Array(minValue...maxValue)
        feature.attributes["BufferSize"] = self.selectedBufferSize
    }
    
    func editRightDetail(cell: UITableViewCell, rightDetailText: String) {
        cell.detailTextLabel?.text = rightDetailText
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

// MARK: Pickerview

extension AddContingentValuesViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return bufferSizes!.count
    }
}

extension AddContingentValuesViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if let bufferSizes = bufferSizes {
            let bufferSizeTitle = String(bufferSizes[row])
            return bufferSizeTitle
        }
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let bufferSizes = bufferSizes {
            selectedBufferSize = bufferSizes[row]
        }
    }
}
