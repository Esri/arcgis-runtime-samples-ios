// Copyright 2022 Esri
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

protocol ContingentValuesViewControllerDelegate: AnyObject {
    func contingentValuesViewController(_ controller: ContingentValuesViewController, didCreate feature: AGSFeature)
}

class ContingentValuesViewController: UITableViewController {
    @IBOutlet var statusCell: UITableViewCell!
    @IBOutlet var protectionCell: UITableViewCell!
    @IBOutlet var bufferSizeCell: UITableViewCell!
    @IBOutlet var doneBarButtonItem: UIBarButtonItem!
    @IBOutlet var bufferSizePickerView: UIPickerView!
    
    // MARK: Actions
    
    @IBAction func cancelBarButtonItemTapped(_ sender: UIBarButtonItem) {
        // Remove the last graphic added.
        graphicsOverlay?.graphics.removeLastObject()
        // Dismiss the table view.
        dismiss(animated: true)
    }
    
    @IBAction func doneBarButtonItemTapped(_ sender: UIBarButtonItem) {
        delegate?.contingentValuesViewController(self, didCreate: feature)
        dismiss(animated: true)
    }
    
    // MARK: Properties
    
    /// The geodatabase's feature table.
    var featureTable: AGSArcGISFeatureTable!
    /// The feature to add to the feature table.
    var feature: AGSArcGISFeature!
    /// An array of buffer sizes valid for the feature.
    var bufferSizes: [Int] = []
    /// The graphics overlay to add the features to.
    var graphicsOverlay: AGSGraphicsOverlay!
    /// Indicates whether the buffer size picker is currently hidden.
    var bufferSizePickerHidden = true
    /// The delegate for the table view controller.
    weak var delegate: ContingentValuesViewControllerDelegate?
    
    /// The selected status value.
    var selectedStatus: AGSCodedValue? {
        didSet {
            if let codedValueName = selectedStatus?.name {
                // Display the selected value.
                editRightDetail(cell: statusCell, rightDetailText: codedValueName)
                // Reset the cell states accordingly.
                resetCellStates()
            }
        }
    }
    
    /// The selected protection value.
    var selectedProtection: AGSContingentCodedValue? {
        didSet {
            let codedValueName = selectedProtection?.codedValue.name
            // Display the selected protection.
            editRightDetail(cell: protectionCell, rightDetailText: codedValueName)
            // Reset the cell states accordingly.
            resetCellStates()
        }
    }
    
    /// The selected buffer size.
    var selectedBufferSize: Int? {
        didSet {
            if let selectedBufferSize = selectedBufferSize {
                // Set the the buffer size attribute to the selected integer.
                feature?.attributes["BufferSize"] = selectedBufferSize
                // Display the selected buffer size.
                bufferSizeCell.detailTextLabel?.text = String(selectedBufferSize)
                // Validate the contingency.
                validateContingency()
            } else {
                // If the value is nil, clear the right detail text.
                editRightDetail(cell: bufferSizeCell, rightDetailText: " ")
                // Hide the buffer size picker.
                toggleBufferSizePickerVisibility()
            }
        }
    }
    
    // MARK: Functions
    
    /// Show the options for the status field.
    func showStatusOptions() {
        // Get the previously selected status value.
        let previouslySelectedStatus = selectedStatus
        // Get the first field by name.
        let statusField = featureTable?.field(forName: "Status")
        // Get the field's domains as coded value domain.
        let codedValueDomain = statusField?.domain as! AGSCodedValueDomain
        // Get the coded value domain's coded values.
        let statusCodedValues = codedValueDomain.codedValues
        // Get the selected index if applicable.
        let selectedIndex = statusCodedValues.firstIndex(where: { $0.name == selectedStatus?.name })
        // Use the coded value names as labels to show the option table view controller.
        let optionsViewController = OptionsTableViewController(labels: statusCodedValues.map(\.name), selectedIndex: selectedIndex) { [weak self] newIndex in
            guard let self = self else { return }
            // Set the selected status.
            self.selectedStatus = statusCodedValues[newIndex]
            // Set the attributes to nil if the status value has changed.
            if self.selectedStatus != previouslySelectedStatus, self.selectedProtection != nil {
                self.selectedProtection = nil
                if self.selectedBufferSize != nil {
                    self.selectedBufferSize = nil
                }
            }
            self.createFeature(with: self.selectedStatus!)
            // Remove the options view controller after selection.
            self.navigationController?.popToViewController(self, animated: true)
        }
        // Set the options view controller's title and present it.
        optionsViewController.title = "Status"
        show(optionsViewController, sender: self)
    }
    
    /// Use the contingent values definition to generate the possible values for the protection field.
    func showProtectionOptions() {
        // Get the previously selected protection value.
        let previouslySelectedProtection = selectedProtection
        guard let feature = feature else { return }
        // Get the contingent value results with the feature for the protection field.
        let contingentValuesResult = featureTable?.contingentValues(with: feature, field: "Protection")
        // Get contingent coded values by field group.
        guard let protectionGroupContingentValues = contingentValuesResult?.contingentValuesByFieldGroup["ProtectionFieldGroup"] as? [AGSContingentCodedValue] else { return }
        // Get the selected index if applicable.
        let selectedIndex = protectionGroupContingentValues.firstIndex(where: { $0.codedValue.name == selectedProtection?.codedValue.name })
        // Use the coded value names as labels to show the option table view controller.
        let optionsViewController = OptionsTableViewController(labels: protectionGroupContingentValues.map(\.codedValue.name), selectedIndex: selectedIndex) { [weak self] newIndex in
            guard let self = self else { return }
            // Set the selected protection value.
            self.selectedProtection = protectionGroupContingentValues[newIndex]
            feature.attributes["Protection"] = self.selectedProtection?.codedValue.code
            // Set the attributes to nil if the protection value has changed.
            if self.selectedProtection != previouslySelectedProtection, self.selectedBufferSize != nil {
                self.selectedBufferSize = nil
            }
            // Remove the options view controller after selection.
            self.navigationController?.popToViewController(self, animated: true)
        }
        // Set the options view controller's title and present it.
        optionsViewController.title = "Protection"
        show(optionsViewController, sender: self)
    }
    
    /// Get the minimum and maximum values of the possible buffer sizes.
    func showBufferSizeOptions() {
        guard let feature = feature else { return }
        // Get the contingent value results using the feature and field.
        let contingentValueResult = featureTable?.contingentValues(with: feature, field: "BufferSize")
        guard let bufferSizeGroupContingentValues = contingentValueResult?.contingentValuesByFieldGroup["BufferSizeFieldGroup"] as? [AGSContingentRangeValue] else { return }
        // Set the minimum and maximum possible buffer sizes.
        let minValue = bufferSizeGroupContingentValues[0].minValue as! Int
        let maxValue = bufferSizeGroupContingentValues[0].maxValue as! Int
        bufferSizes = Array(minValue...maxValue)
        // Select the buffer size if it is the only option available.
        if bufferSizes.count == 1 {
            selectedBufferSize = bufferSizes[0]
        }
        // Update the picker view.
        bufferSizePickerView.reloadAllComponents()
    }
    
    func createFeature(with status: AGSCodedValue) {
        // Get the contingent values definition from the feature table.
        let contingentValuesDefinition = featureTable?.contingentValuesDefinition
        // Load the contingent values definition.
        contingentValuesDefinition?.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else if let feature = self.featureTable?.createFeature() as? AGSArcGISFeature {
                // Create a feature from the feature table and set the initial attribute.
                feature.attributes["Status"] = status.code
                self.feature = feature
            }
        }
    }

    /// Ensure that the selected values are a valid combination.
    func validateContingency() {
        guard let featureTable = featureTable, let feature = feature else { return }
        // Validate the feature's contingencies.
        let contingencyViolations = featureTable.validateContingencyConstraints(with: feature)
        if contingencyViolations.isEmpty {
            // If there are no contingency violations in the array, the feature is valid and ready to add to the feature table.
            doneBarButtonItem.isEnabled = true
        } else {
            // Present an alert if there are contingency violations.
            presentAlert(title: "", message: "Invalid contingent values")
        }
    }
    
    // MARK: UI Functions
    
    /// Update the cell's right detail.
    func editRightDetail(cell: UITableViewCell, rightDetailText: String?) {
        cell.detailTextLabel?.text = rightDetailText
    }
    
    /// Reset the cell states according to which values have already been selected.
    func resetCellStates() {
        if selectedStatus == nil {
            protectionCell.textLabel?.isEnabled = false
            protectionCell.isUserInteractionEnabled = false
        } else {
            protectionCell.textLabel?.isEnabled = true
            protectionCell.isUserInteractionEnabled = true
        }
        if selectedProtection == nil {
            bufferSizeCell.textLabel?.isEnabled = false
            bufferSizeCell.isUserInteractionEnabled = false
        } else {
            bufferSizeCell.textLabel?.isEnabled = true
            bufferSizeCell.isUserInteractionEnabled = true
        }
    }
    
    /// Toggles visibility of the buffer size scale picker.
    func toggleBufferSizePickerVisibility() {
        let bufferSizePicker = IndexPath(row: 3, section: 0)
        tableView.performBatchUpdates({
            if bufferSizePickerHidden {
                tableView.insertRows(at: [bufferSizePicker], with: .fade)
                bufferSizePickerHidden = false
            } else {
                tableView.deleteRows(at: [bufferSizePicker], with: .fade)
                bufferSizePickerHidden = true
            }
        }, completion: nil)
    }
    
    // MARK: UITableViewController
    
    /// Show the list of options according to the selected row.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch cell {
        case statusCell:
            showStatusOptions()
        case protectionCell:
            showProtectionOptions()
        case bufferSizeCell:
            tableView.deselectRow(at: indexPath, animated: true)
            showBufferSizeOptions()
            toggleBufferSizePickerVisibility()
        default:
            return
        }
    }
        
    /// Return the number of rows depending on the picker view.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let numberOfRows = super.tableView(tableView, numberOfRowsInSection: section)
        if bufferSizePickerHidden {
            return numberOfRows - 1
        } else {
            return numberOfRows
        }
    }
}

// MARK: Pickerview

extension ContingentValuesViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return bufferSizes.count
    }
}

extension ContingentValuesViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let bufferSizeTitle = String(bufferSizes[row])
        return bufferSizeTitle
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedBufferSize = bufferSizes[row]
    }
}
