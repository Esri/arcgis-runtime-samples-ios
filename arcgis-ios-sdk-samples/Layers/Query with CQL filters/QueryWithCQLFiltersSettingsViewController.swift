// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

protocol QueryWithCQLFiltersSettingsViewControllerDelegate: AnyObject {
    func settingsViewController(_ controller: QueryWithCQLFiltersSettingsViewController, didCreate queryParameters: AGSQueryParameters)
}

class QueryWithCQLFiltersSettingsViewController: UITableViewController {
    // MARK: Storyboard views
    
    /// The cell for where clause options.
    @IBOutlet var whereClauseCell: UITableViewCell! {
        didSet {
            whereClauseCell.detailTextLabel?.text = selectedWhereClause
        }
    }
    /// The text field for max features input.
    @IBOutlet var maxFeaturesTextField: UITextField! {
        didSet {
            // Add a toolbar to dismiss keyboard.
            let toolbar = UIToolbar()
            let items: [UIBarButtonItem] = [
                .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                .init(barButtonSystemItem: .done, target: self, action: #selector(inputAccessoryViewDoneButtonTapped(_:)))
            ]
            toolbar.setItems(items, animated: true)
            toolbar.sizeToFit()
            maxFeaturesTextField.inputAccessoryView = toolbar
            
            maxFeaturesTextField.delegate = self
            updateMaxFeaturesTextField(value: maxFeatures)
        }
    }
    /// The start date picker.
    @IBOutlet var startDatePicker: UIDatePicker!
    /// The end date picker.
    @IBOutlet var endDatePicker: UIDatePicker!
    /// The switch to control if date pickers are enabled.
    @IBOutlet var dateFilterSwitch: UISwitch!
    
    // MARK: Properties
    
    /// A delegate to notify other view controllers.
    weak var delegate: QueryWithCQLFiltersSettingsViewControllerDelegate?
    
    let numberFormatter = NumberFormatter()
    let sampleWhereClauses: [String] = [
        // Sample Query 1: Features with an F_CODE property of "AP010".
        // A cql-text query.
        "F_CODE = 'AP010'",
        // A cql-json query.
        #"{"eq":[{"property":"F_CODE"},"AP010"]}"#,
        // Sample Query 2: Features with an F_CODE property matching the pattern.
        "F_CODE LIKE 'AQ%'",
        // Sample Query 3: Use cql-json to combine "before" and "eq" operators
        // with the logical "and" operator.
        #"{"and":[{"eq":[{"property":"F_CODE"},"AP010"]},{"before":[{"property":"ZI001_SDV"},"2013-01-01"]}]}"#
    ]
    var selectedWhereClause: String = ""
    var maxFeatures: NSNumber = 1_000
    
    // MARK: Methods
    
    func makeQueryParameters() -> AGSQueryParameters {
        let queryParameters = AGSQueryParameters()
        queryParameters.whereClause = selectedWhereClause
        queryParameters.maxFeatures = maxFeatures.intValue
        if dateFilterSwitch.isOn {
            queryParameters.timeExtent = AGSTimeExtent(startTime: startDatePicker.date, endTime: endDatePicker.date)
        }
        return queryParameters
    }
    
    func showWhereClausePicker() {
        let selectedIndex = sampleWhereClauses.firstIndex { $0 == selectedWhereClause }
        let optionsViewController = OptionsTableViewController(labels: sampleWhereClauses, selectedIndex: selectedIndex) { newIndex in
            let whereClause = self.sampleWhereClauses[newIndex]
            self.selectedWhereClause = whereClause
            self.whereClauseCell.detailTextLabel?.text = whereClause
            self.navigationController?.popViewController(animated: true)
        }
        optionsViewController.title = "Where Clause"
        show(optionsViewController, sender: self)
    }
    
    /// Set the date picker limits to maintain a valid state.
    func updateDatePickerLimits() {
        // Keep the start date less than the end date.
        startDatePicker.maximumDate = Calendar.current.date(byAdding: .day, value: -1, to: endDatePicker.date)
        // Keep the end date greater than the start date.
        endDatePicker.minimumDate = Calendar.current.date(byAdding: .day, value: 1, to: startDatePicker.date)
    }
    
    func updateMaxFeaturesTextField(value: NSNumber) {
        maxFeaturesTextField.text = numberFormatter.string(from: value)
    }
    
    // MARK: Actions
    
    @objc
    func inputAccessoryViewDoneButtonTapped(_ sender: UIBarButtonItem) {
        maxFeaturesTextField.resignFirstResponder()
    }
    
    @IBAction func datePickerAction(_ sender: Any) {
        updateDatePickerLimits()
    }
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func applyAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
        delegate?.settingsViewController(self, didCreate: makeQueryParameters())
    }
    
    @IBAction func textFieldEditingDidEnd(_ sender: UITextField) {
        if let text = sender.text,
           let value = self.numberFormatter.number(from: text),
           value.intValue > 0 {
            maxFeatures = value
        } else {
            // Reset to the previous value if the input is invalid.
            updateMaxFeaturesTextField(value: maxFeatures)
        }
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        startDatePicker.isEnabled = sender.isOn
        endDatePicker.isEnabled = sender.isOn
    }
    
    // MARK: UITableViewController
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch cell {
        case whereClauseCell:
            showWhereClausePicker()
        default:
            return
        }
    }
}

// MARK: - UITextFieldDelegate

extension QueryWithCQLFiltersSettingsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
