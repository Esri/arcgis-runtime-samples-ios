// Copyright 2020 Esri
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

class ConfigureSubnetworkTraceOptionsViewController: UITableViewController {
    @IBOutlet var attributesCell: UITableViewCell!
    @IBOutlet var comparisonCell: UITableViewCell!
    @IBOutlet var valueCell: UITableViewCell!
    
    /// An array of possible network attributes.
    var possibleAttributes: [AGSUtilityNetworkAttribute]!
    /// The attribute selected by the user.
    var selectedAttribute: AGSUtilityNetworkAttribute? {
        didSet {
            // Reset the selected value.
            attributesCell.detailTextLabel?.text = selectedAttribute?.name
            selectedValue = nil
            updateCellStates()
        }
    }
    /// The comparison selected by the user.
    var selectedComparison: AGSUtilityAttributeComparisonOperator? {
        didSet {
            if let index = comparisons.firstIndex(where: { $0.0 == selectedComparison }) {
                comparisonCell.detailTextLabel?.text = comparisons[index].1
            }
            updateCellStates()
        }
    }
    /// The value selected by the user.
    var selectedValue: String? {
        didSet {
            valueCell.detailTextLabel?.text = selectedValue
        }
    }
    
    var emptyStringObserver: Any!
    
    /// An array of pairs of `AGSUtilityAttributeComparisonOperator` and their name strings.
    let comparisons: KeyValuePairs<AGSUtilityAttributeComparisonOperator, String> = [
        .equal: "Equal",
        .notEqual: "NotEqual",
        .greaterThan: "GreaterThan",
        .greaterThanEqual: "GreaterThanEqual",
        .lessThan: "LessThan",
        .lessThanEqual: "LessThanEqual",
        .includesTheValues: "IncludesTheValues",
        .doesNotIncludeTheValues: "DoesNotIncludeTheValues",
        .includesAny: "IncludesAny",
        .doesNotIncludeAny: "DoesNotIncludeAny"
    ]
    
    /// A dictionary of `AGSUtilityCategoryComparisonOperators`.
    /// - Note: You may also create a `AGSUtilityCategoryComparison` with
    ///         `AGSUtilityNetworkDefinition.categories` and `AGSUtilityCategoryComparisonOperator`.
    // let categoryComparisonOperators: KeyValuePairs<AGSUtilityCategoryComparisonOperator, String> = [
    //     .exists: "exists",
    //     .doesNotExist: "doesNotExist"
    // ]
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        // deselect row manually
        if cell == valueCell {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        switch cell {
        case attributesCell:
            showAttributePicker()
        case comparisonCell:
            showComparisonPicker()
        case valueCell:
            showValueInputField { [weak self] value in
                self?.selectedValue = value?.stringValue
                self?.valueCell.detailTextLabel?.text = value?.stringValue
            }
        default:
            fatalError("Unknown cell type")
        }
    }
    
    func updateCellStates() {
        // Disable the value cell when attribute is unspecified.
        if selectedAttribute == nil {
            valueCell.textLabel?.isEnabled = false
            valueCell.isUserInteractionEnabled = false
        } else {
            if selectedAttribute?.domain as? AGSCodedValueDomain != nil {
                // Indicate that a new view controller will display.
                valueCell.accessoryType = .disclosureIndicator
            } else {
                // Indicate that an alert will show.
                valueCell.accessoryType = .none
            }
            valueCell.textLabel?.isEnabled = true
            valueCell.isUserInteractionEnabled = true
        }
    }
    
    func showAttributePicker() {
        let selectedIndex = possibleAttributes.firstIndex { $0 == selectedAttribute } ?? -1
        let optionsViewController = OptionsTableViewController(labels: possibleAttributes.map { $0.name }, selectedIndex: selectedIndex) { (newIndex) in
            self.selectedAttribute = self.possibleAttributes[newIndex]
        }
        optionsViewController.title = "Attributes"
        show(optionsViewController, sender: self)
    }
    
    func showComparisonPicker() {
        let selectedIndex = selectedComparison?.rawValue ?? -1
        let optionsViewController = OptionsTableViewController(labels: comparisons.map { $0.1 }, selectedIndex: selectedIndex) { (newIndex) in
            self.selectedComparison = self.comparisons[newIndex].0
        }
        optionsViewController.title = "Comparison"
        show(optionsViewController, sender: self)
    }
    
    func showValueInputField(completion: @escaping (NSNumber?) -> Void) {
        let alertController = UIAlertController(title: "Provide a comparison value", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let doneAction = UIAlertAction(title: "Done", style: .default) { [textField = alertController.textFields?.first] _ in
            // If the text field is empty, do nothing.
            NotificationCenter.default.removeObserver(
                self.emptyStringObserver!,
                name: UITextField.textDidChangeNotification,
                object: textField
            )
            guard let text = textField?.text, !text.isEmpty else { return }
            // Convert the string to a number.
            let formatter = NumberFormatter()
            if let value = formatter.number(from: text) {
                completion(value)
            } else {
                completion(nil)
            }
        }
        alertController.addTextField { textField in
            textField.keyboardType = .numbersAndPunctuation
            textField.placeholder = "e.g. 15"
            // Add an observer to ensure the user does not input an empty string.
            self.emptyStringObserver = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: .main
            ) { _ in
                // Get the character count of non-whitespace characters.
                let textCount = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).count ?? 0
                let textIsNotEmpty = textCount > 0
                
                // Enable the done button if the textfield is not empty.
                doneAction.isEnabled = textIsNotEmpty
            }
        }
        // Add actions to alert controller.
        alertController.addAction(cancelAction)
        alertController.addAction(doneAction)
        alertController.preferredAction = doneAction
        present(alertController, animated: true)
    }
    
    deinit {
        print("✅ options deinit")
    }
}

// MARK: - UITextFieldDelegate

extension ConfigureSubnetworkTraceOptionsViewController: UITextFieldDelegate {
    // Ensure that the text field will only accept numbers.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let validCharacters = ".-0123456789"
        return CharacterSet(charactersIn: validCharacters).isSuperset(of: CharacterSet(charactersIn: text))
    }
}
