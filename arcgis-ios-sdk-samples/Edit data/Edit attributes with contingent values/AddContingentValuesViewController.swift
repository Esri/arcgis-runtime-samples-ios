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

protocol ContingentValuesDelegate: AnyObject {
    func createBufferGraphics()
}

class AddContingentValuesViewController: UITableViewController {
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
    
    @IBAction func doneBarButtonItemTapped(_ sender: Any) {
        guard let feature = feature, let featureTable = featureTable else { return }
        // Set the feature's geometry to the map point.
        feature.geometry = mapPoint
        // Add the feature to the feature table.
        featureTable.add(feature) { _ in
            // Create buffer graphics for the new feature.
            self.delegate?.createBufferGraphics()
            self.dismiss(animated: true)
        }
    }
    
    // MARK: Properties
    
    /// The geodatabase's feature table.
    var featureTable: AGSArcGISFeatureTable?
    /// The feature to add to the feature table.
    var feature: AGSArcGISFeature?
    /// The point on the map to add the feature to.
    var mapPoint: AGSPoint?
    /// An array of buffer sizes valid for the feature.
    var bufferSizes: [Int]?
    /// The graphics overlay to add the features to.
    var graphicsOverlay: AGSGraphicsOverlay?
    /// Indicates whether the buffer size picker is currently hidden.
    var bufferSizePickerHidden = true
    /// The delegate for the table view controller.
    weak var delegate: ContingentValuesDelegate?
    
    /// The selected status value.
    var selectedStatus: AGSCodedValue? {
        didSet {
            if let codedValueName = selectedStatus?.name {
                // Display the selected value name.
                editRightDetail(cell: statusCell, rightDetailText: codedValueName)
                // Reset the cell states accordingly.
                resetCellStates()
            }
        }
    }
    
    /// The selected protection value.
    var selectedProtection: AGSContingentCodedValue? {
        didSet {
            // Display the value name or empty string.
            let codedValueName = selectedProtection?.codedValue.name
            editRightDetail(cell: protectionCell, rightDetailText: codedValueName)
            resetCellStates()
        }
    }
    
    /// The selected buffer size.
    var selectedBufferSize: Int? {
        didSet {
            feature?.attributes["BufferSize"] = self.selectedBufferSize
            if let selectedBufferSize = selectedBufferSize {
                let bufferSize = String(selectedBufferSize)
                editRightDetail(cell: bufferSizeCell, rightDetailText: bufferSize)
                validateContingency()
            } else {
                editRightDetail(cell: bufferSizeCell, rightDetailText: " ")
                bufferSizePickerHidden = false
                toggleBufferSizePickerVisibility()
            }
        }
    }
    
    // MARK: Functions
    
    /// Show the options for the status field.
    func showStatusOptions() {
        let previouslySelectedStatus = selectedStatus
        guard let featureTable = featureTable else { return }
        let statusField = featureTable.field(forName: "Status")
        let codedValueDomain = statusField?.domain as! AGSCodedValueDomain
        let status = codedValueDomain.codedValues
        let selectedIndex = status.firstIndex { $0.name == self.selectedStatus?.name } ?? nil
        let optionsViewController = OptionsTableViewController(labels: status.map { $0.name }, selectedIndex: selectedIndex) { newIndex in
            self.selectedStatus = status[newIndex]
            if self.selectedStatus != previouslySelectedStatus, self.selectedProtection != nil {
                self.selectedProtection = nil
                if self.selectedBufferSize != nil {
                    self.selectedBufferSize = nil
                }
            }
            self.navigationController?.popViewController(animated: true)
        }
        optionsViewController.title = "Status"
        self.show(optionsViewController, sender: self)
    }
    
    /// Use the contingent values definition to generate the possible values for the protection field.
    func showProtectionOptions() {
        let previouslySelectedProtection = selectedProtection
        featureTable?.load { [weak self] error in
            guard let self = self else { return }
            let contingentValuesDefinition = self.featureTable?.contingentValuesDefinition
            contingentValuesDefinition?.load { error in
                if let feature = self.featureTable?.createFeature() as? AGSArcGISFeature {
                    feature.attributes["Status"] = self.selectedStatus?.code
                    self.feature = feature
                    let contingentValuesResult = self.featureTable?.contingentValues(with: feature, field: "Protection")
                    guard let protectionGroupContingentValues = contingentValuesResult?.contingentValuesByFieldGroup["ProtectionFieldGroup"] as? [AGSContingentCodedValue] else { return }
                    let selectedIndex = protectionGroupContingentValues.firstIndex { $0.codedValue.name == self.selectedProtection?.codedValue.name} ?? nil
                    let optionsViewController = OptionsTableViewController(labels: protectionGroupContingentValues.map { $0.codedValue.name }, selectedIndex: selectedIndex) { newIndex in
                        self.selectedProtection = protectionGroupContingentValues[newIndex]
                        if self.selectedProtection != previouslySelectedProtection, self.selectedBufferSize != nil {
                            self.selectedBufferSize = nil
                        }
                        feature.attributes["Protection"] = self.selectedProtection?.codedValue.code
                        self.navigationController?.popViewController(animated: true)
                    }
                    optionsViewController.title = "Protection"
                    self.show(optionsViewController, sender: self)
                }
            }
        }
    }
    
    /// Get the minimum and maximum values of the possible buffer sizes.
    func showBufferSizeOptions() {
        guard let feature = feature else { return }
        let contingentValueResult = featureTable?.contingentValues(with: feature, field: "BufferSize")
        guard let bufferSizeGroupContingentValues = contingentValueResult?.contingentValuesByFieldGroup["BufferSizeFieldGroup"] as? [AGSContingentRangeValue] else { return }
        let minValue = bufferSizeGroupContingentValues[0].minValue as! Int
        let maxValue = bufferSizeGroupContingentValues[0].maxValue as! Int
        bufferSizes = Array(minValue...maxValue)
        if bufferSizes?.count == 1 {
            selectedBufferSize = bufferSizes?[0]
        }
        bufferSizePickerView.reloadAllComponents()
    }
    
    /// Ensure that the selected values are a valid combination.
    func validateContingency() {
        guard let featureTable = featureTable, let feature = feature else { return }
        let contingencyViolations = featureTable.validateContingencyConstraints(with: feature)
        if contingencyViolations.isEmpty {
            self.doneBarButtonItem.isEnabled = true
        } else {
            self.presentAlert(title: "", message: "Invalid contingent values")
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
    
    /// Toggles visisbility of the buffer size scale picker.
    func toggleBufferSizePickerVisibility() {
        let bufferSizePicker = IndexPath(row: 3, section: 0)
        let bufferSizeLabel = bufferSizeCell.detailTextLabel
        tableView.performBatchUpdates({
            if bufferSizePickerHidden {
                bufferSizeLabel?.textColor = .accentColor
                tableView.insertRows(at: [bufferSizePicker], with: .fade)
                bufferSizePickerHidden = false
            } else {
                bufferSizeLabel?.textColor = nil
                tableView.deleteRows(at: [bufferSizePicker], with: .fade)
                bufferSizePickerHidden = true
            }
        }, completion: nil)
    }
    
    // MARK: UITableViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
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
            if selectedProtection != nil {
                toggleBufferSizePickerVisibility()
            } else {
                return
            }
        default:
            return
        }
    }
        
    /* UITableViewDataSource */
    
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
