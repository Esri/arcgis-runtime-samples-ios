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

protocol ConfigureSubnetworkTraceOptionsViewControllerDelegate: AnyObject {
    func optionsViewController(_ controller: ConfigureSubnetworkTraceOptionsViewController, didCreate: AGSUtilityTraceConditionalExpression)
}

class ConfigureSubnetworkTraceOptionsViewController: UITableViewController {
    // MARK: Storyboard views
    
    /// The cell for attribute options.
    @IBOutlet var attributesCell: UITableViewCell!
    /// The cell for comparison operator options.
    @IBOutlet var comparisonCell: UITableViewCell!
    /// The cell for value to compare with.
    @IBOutlet var valueCell: UITableViewCell!
    /// A button to add the conditional expression to the trace configuration.
    @IBOutlet var doneBarButtonItem: UIBarButtonItem!
    
    // MARK: Properties
    
    /// A delegate to notify other view controllers.
    weak var delegate: ConfigureSubnetworkTraceOptionsViewControllerDelegate?
    
    /// An array of possible network attributes.
    var possibleAttributes = [AGSUtilityNetworkAttribute]()
    
    /// The attribute selected by the user.
    var selectedAttribute: AGSUtilityNetworkAttribute? {
        didSet {
            // Set the selected attribute name.
            attributesCell.detailTextLabel?.text = selectedAttribute?.name
            // Reset the selected value.
            selectedValue = nil
            valueCell.detailTextLabel?.text = nil
            updateCellStates()
        }
    }
    /// The comparison selected by the user.
    var selectedComparison: AGSUtilityAttributeComparisonOperator? {
        didSet {
            if let selectedComparisonString = selectedComparison?.title {
                comparisonCell.detailTextLabel?.text = selectedComparisonString
            } else {
                comparisonCell.detailTextLabel?.text = nil
            }
            doneBarButtonItem.isEnabled = selectedComparison != nil && selectedValue != nil
        }
    }
    /// The value selected by the user.
    var selectedValue: Any? {
        didSet {
            doneBarButtonItem.isEnabled = selectedComparison != nil && selectedValue != nil
        }
    }
    
    // MARK: Actions
    
    @IBAction func addConditionBarButtonItemTapped(_ sender: UIBarButtonItem) {
        if let attribute = selectedAttribute, let comparison = selectedComparison, let value = selectedValue {
            let convertedValue: Any
            
            if let codedValue = value as? AGSCodedValue, attribute.domain is AGSCodedValueDomain {
                // The value is a coded value.
                convertedValue = convertToDataType(value: codedValue.code!, dataType: attribute.dataType)
            } else {
                // The value is from user input.
                convertedValue = convertToDataType(value: value, dataType: attribute.dataType)
            }
            
            if let expression = AGSUtilityNetworkAttributeComparison(networkAttribute: attribute, comparisonOperator: comparison, value: convertedValue) {
                // Create and pass the valid expression back to the main view controller.
                delegate?.optionsViewController(self, didCreate: expression)
            }
        }
        dismiss(animated: true)
    }
    
    @IBAction func cancelBarButtonItemTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    // MARK: UI and data binding methods
    
    /// Convert the values to matching data types.
    ///
    /// - Parameters:
    ///   - value: The right hand side value used in the conditional expression.
    ///   - dataType: An `AGSUtilityNetworkAttributeDataType` enum case.
    ///
    /// - Note: The input value can either be an `AGSCodedValue` populated from the left hand side
    ///         attribute's domain, or a numeric value entered by the user.
    ///
    /// - Returns: Converted value.
    func convertToDataType(value: Any, dataType: AGSUtilityNetworkAttributeDataType) -> Any {
        switch dataType {
        case .integer:
            return value as! Int64
        case .float:
            return value as! Float
        case .double:
            return value as! Double
        case .boolean:
            return value as! Bool
        default:
            return value
        }
    }
    
    func updateCellStates() {
        // Disable the value cell when attribute is unspecified.
        if let selectedAttribute = selectedAttribute {
            if selectedAttribute.domain is AGSCodedValueDomain {
                // Indicate that a new view controller will display.
                valueCell.accessoryType = .disclosureIndicator
            } else {
                // Indicate that an alert will show.
                valueCell.accessoryType = .none
            }
            valueCell.textLabel?.isEnabled = true
            valueCell.isUserInteractionEnabled = true
        } else {
            // Enable the value cell when an attribute is specified.
            valueCell.textLabel?.isEnabled = false
            valueCell.isUserInteractionEnabled = false
        }
    }
    
    // Transition to the attribute options view controller.
    func showAttributePicker() {
        let selectedIndex = possibleAttributes.firstIndex { $0 == selectedAttribute } ?? -1
        let optionsViewController = OptionsTableViewController(labels: possibleAttributes.map { $0.name }, selectedIndex: selectedIndex) { newIndex in
            self.selectedAttribute = self.possibleAttributes[newIndex]
            self.navigationController?.popViewController(animated: true)
        }
        optionsViewController.title = "Attributes"
        show(optionsViewController, sender: self)
    }
    
    // Transition to the comparison options view controller.
    func showComparisonPicker() {
        let selectedIndex = selectedComparison?.rawValue ?? -1
        // An array of `AGSUtilityAttributeComparisonOperator` init from their raw value.
        let attributeComparisonOperators = (0...9).map { AGSUtilityAttributeComparisonOperator(rawValue: $0)! }
        let optionsViewController = OptionsTableViewController(labels: attributeComparisonOperators.map { $0.title }, selectedIndex: selectedIndex) { newIndex in
            self.selectedComparison = attributeComparisonOperators[newIndex]
            self.navigationController?.popViewController(animated: true)
        }
        optionsViewController.title = "Comparison"
        show(optionsViewController, sender: self)
    }
    
    // Transition to the value options view controller.
    func showValuePicker(values: [AGSCodedValue]) {
        let selectedIndex = -1
        let valueLabels = values.map { $0.name }
        let optionsViewController = OptionsTableViewController(labels: valueLabels, selectedIndex: selectedIndex) { newIndex in
            self.selectedValue = values[newIndex]
            self.valueCell.detailTextLabel?.text = valueLabels[newIndex]
            self.navigationController?.popViewController(animated: true)
        }
        optionsViewController.title = "Value"
        show(optionsViewController, sender: self)
    }
    
    // Prompt an alert to allow the user to input custom values.
    func showValueInputField(completion: @escaping (NSNumber?) -> Void) {
        // Create an object to observe if text field input is empty.
        var textFieldObserver: NSObjectProtocol!
        
        let alertController = UIAlertController(title: "Provide a comparison value", message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Remove observer when canceled.
            NotificationCenter.default.removeObserver(textFieldObserver!)
        }
        let doneAction = UIAlertAction(title: "Done", style: .default) { _ in
            let textField = alertController.textFields!.first!
            // Remove the observer when done button is no longer in use.
            NotificationCenter.default.removeObserver(textFieldObserver!)
            // Convert the string to a number.
            completion(NumberFormatter().number(from: textField.text!))
        }
        // Add the done action to the alert controller.
        doneAction.isEnabled = false
        alertController.addAction(doneAction)
        // Add a text field to the alert controller.
        alertController.addTextField { textField in
            textField.keyboardType = .numbersAndPunctuation
            textField.placeholder = "e.g. 15"
        }
        // Add an observer to ensure the user does not input an empty string.
        textFieldObserver = NotificationCenter.default.addObserver(
            forName: UITextField.textDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            if let text = alertController.textFields!.first!.text {
                // Enable the done button if the textfield is not empty and is a valid number.
                doneAction.isEnabled = NumberFormatter().number(from: text) != nil
            } else {
                doneAction.isEnabled = false
            }
        }
        // Add a cancel action to alert controller.
        alertController.addAction(cancelAction)
        alertController.preferredAction = doneAction
        present(alertController, animated: true)
    }
    
    // MARK: UITableViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedAttribute = nil
        selectedComparison = nil
        selectedValue = nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath)
        switch cell {
        case attributesCell:
            showAttributePicker()
        case comparisonCell:
            showComparisonPicker()
        case valueCell:
            if let domain = selectedAttribute?.domain as? AGSCodedValueDomain {
                showValuePicker(values: domain.codedValues)
            } else {
                showValueInputField { [weak self] value in
                    // Assign an `NSNumber?` to selected value so that it can cast to numbers.
                    self?.selectedValue = value
                    self?.valueCell.detailTextLabel?.text = value?.stringValue
                    // Mitigate the Apple's UI bug in right detail cell.
                    self?.tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        default:
            fatalError("Unknown cell type")
        }
    }
}
