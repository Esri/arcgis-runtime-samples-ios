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
    func settingsViewController(_ controller: QueryWithCQLFiltersSettingsViewController, queryParameters: AGSQueryParameters)
}

class QueryWithCQLFiltersSettingsViewController: UITableViewController {
    // MARK: Storyboard views
    
    /// The cell for where clause options.
    @IBOutlet var whereClauseCell: UITableViewCell!
    /// The cell for max features input.
    @IBOutlet var maxFeaturesCell: UITableViewCell!
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
    let sampleWhereClauses = [
        // Sample Query 1, cql-text, cql-json.
        "F_CODE = 'AP010'",
        "{\"eq\":{\"property\":\"F_CODE\",\"value\":\"AP010\"}}",
        // Sample Query 2.
        "F_CODE LIKE 'AQ%'",
        "{\"like\":{\"property\":\"F_CODE\",\"value\":\"AQ%\"}}",
        // Sample Query 3: use cql-json to combine "before" and "after" temporal
        // operators with the logcial "and" operator
        "{\"and\":[{\"after\":{\"property\":\"ZI001_SDV\", \"value\":\"2011-12-31\"}},{\"before\":{\"property\":\"ZI001_SDV\",\"value\":\"2013-01-01\"}}]}"
    ]
    var selectedWhereClause: String?
    var maxFeatures: Int?
    
    // MARK: Methods and Actions
    
    func makeQueryParameters() -> AGSQueryParameters {
        let queryParameters = AGSQueryParameters()
        queryParameters.whereClause = selectedWhereClause ?? ""
        queryParameters.maxFeatures = maxFeatures ?? 1_000
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
    
    /// Prompt an alert to allow the user to input a numeric value.
    func showValueInputField(completion: @escaping (NSNumber?) -> Void) {
        // Create an object to observe if text field input is empty.
        var textFieldObserver: NSObjectProtocol!
        let alertController = UIAlertController(
            title: "Provide the max features query parameter.",
            message: nil,
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Remove observer when cancelled.
            NotificationCenter.default.removeObserver(textFieldObserver!)
        }
        let doneAction = UIAlertAction(title: "Done", style: .default) { [unowned alertController] _ in
            // Remove the observer when done button is no longer in use.
            NotificationCenter.default.removeObserver(textFieldObserver!)
            let textField = alertController.textFields!.first!
            // Convert the string to a number.
            completion(self.numberFormatter.number(from: textField.text!))
        }
        alertController.addAction(doneAction)
        alertController.addAction(cancelAction)
        alertController.preferredAction = doneAction
        // Add a text field to the alert controller.
        alertController.addTextField { textField in
            textField.keyboardType = .numberPad
            textField.placeholder = "e.g. 1000"
            textField.text = "1000"
            // Add an observer to ensure the user does not input an empty string.
            textFieldObserver = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: .main
            ) { [unowned doneAction] _ in
                if let text = textField.text {
                    // Enable if the textfield is not empty and is a valid number.
                    doneAction.isEnabled = self.numberFormatter.number(from: text) != nil
                } else {
                    doneAction.isEnabled = false
                }
            }
        }
        present(alertController, animated: true)
    }
    
    /// Set the date picker limits to maintain a valid state.
    func updateDatePickerLimits() {
        // Keep the start date less than the end date.
        startDatePicker.maximumDate = Calendar.current.date(byAdding: .day, value: -1, to: endDatePicker.date)
        // Keep the end date greater than the start date.
        endDatePicker.minimumDate = Calendar.current.date(byAdding: .day, value: 1, to: startDatePicker.date)
    }
    
    @IBAction func datePickerAction(_ sender: Any) {
        updateDatePickerLimits()
    }
    
    @IBAction func cancelAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func applyAction(_ sender: UIBarButtonItem) {
        delegate?.settingsViewController(self, queryParameters: makeQueryParameters())
        dismiss(animated: true)
    }
    
    @IBAction func switchValueChanged(_ sender: UISwitch) {
        startDatePicker.isEnabled = sender.isOn
        endDatePicker.isEnabled = sender.isOn
    }
    
    // MARK: UITableViewController
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        switch cell {
        case whereClauseCell:
            showWhereClausePicker()
        case maxFeaturesCell:
            showValueInputField { [weak self] value in
                guard let self = self else { return }
                self.maxFeaturesCell.detailTextLabel?.text = value?.stringValue
                self.maxFeatures = value?.intValue
                // Mitigate the Apple's UI bug in right detail cell.
                tableView.reloadRows(at: [indexPath], with: .none)
            }
        default:
            return
        }
    }
}
