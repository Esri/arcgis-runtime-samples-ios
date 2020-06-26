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

class ConfigureSubnetworkTraceViewController: UITableViewController {
    // Reference to the switches.
    @IBOutlet weak var barriersSwitch: UISwitch!
    @IBOutlet weak var containersSwitch: UISwitch!
    // References to interactable cells.
    @IBOutlet weak var attributesCell: UITableViewCell!
    @IBOutlet weak var comparisonCell: UITableViewCell!
    @IBOutlet weak var valueCell: UITableViewCell!
    @IBOutlet weak var addConditionLabel: UILabel!
    @IBOutlet weak var resetLabel: UILabel!
    @IBOutlet weak var traceLabel: UILabel!
    // References to labels.
    @IBOutlet weak var attributeLabel: UILabel!
    @IBOutlet weak var comparisonLabel: UILabel!
    @IBOutlet weak var valueButton: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    // References to cells that act as buttons.
    @IBOutlet weak var addConditionButton: UITableViewCell!
    @IBOutlet weak var resetButton: UITableViewCell!
    @IBOutlet weak var traceButton: UITableViewCell!
    // Reference to the text view.
    @IBOutlet weak var textView: UITextView!
    // References to the switch actions.
    @IBAction func barriersSwitchAction(_ sender: UISwitch) {
        sourceTier?.traceConfiguration?.includeBarriers = sender.isOn
    }
    @IBAction func containersSwitchAction(_ sender: UISwitch) {
        sourceTier?.traceConfiguration?.includeContainers = sender.isOn
    }
    
    // An array of the types of AGSUtilityAttributeComparisonOperators as strings.
    let comparisonsStrings = ["Equal", "NotEqual", "GreaterThan", "GreaterThanEqual", "LessThan", "LessThanEqual", "IncludesTheValues", "DoesNotIncludeTheValues", "IncludesAny", "DoesNotIncludeAny"]
    // An array of the types of AGSUtilityAttributeComparisonOperators.
    let comparisons: [AGSUtilityAttributeComparisonOperator] = [.equal, .notEqual, .greaterThan, .greaterThanEqual, .lessThan, .lessThanEqual, .includesTheValues, .doesNotIncludeTheValues, .includesAny, .doesNotIncludeAny]
    // A dictionary of AGSUtilityCategoryComparisonOperators.
    let categoryComparisonOperators: [AGSUtilityCategoryComparisonOperator: String] = [.exists: "exists", .doesNotExist: "doesNotExist" ]
    
    var utilityNetwork: AGSUtilityNetwork = {
        // Feature service for an electric utility network in Naperville, Illinois.
        let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!
        return AGSUtilityNetwork(url: featureServiceURL)
    }()
    // Utility element to start the trace from.
    var startingLocation: AGSUtilityElement?
    // Holding the initial conditional expression.
    var initialExpression: AGSUtilityTraceConditionalExpression?
    // The trace configuration.
    var configuration: AGSUtilityTraceConfiguration?
    // The source tier of the utility network.
    var sourceTier: AGSUtilityTier?
    // Arrays of attributes, values, and their respective labels.
    var valueLabels: [String] = []
    // The attribute selected by the user.
    var selectedAttribute: AGSUtilityNetworkAttribute? {
        didSet {
            updateButtons()
        }
    }
    // The comparison selected by the user.
    var selectedComparison: AGSUtilityAttributeComparisonOperator? {
        didSet {
            updateButtons()
        }
    }
    // The value selected by the user.
    var selectedValue: Any? {
        didSet {
            updateButtons()
        }
    }
    
    func loadUtilityNetwork() {
        // For creating the default starting location.
        let deviceTableName = "Electric Distribution Device"
        let assetGroupName = "Circuit Breaker"
        let assetTypeName = "Three Phase"
        let globalID = UUID(uuidString: "1CAF7740-0BF4-4113-8DB2-654E18800028")
        // For creating the default trace configuration.
        let domainNetworkName = "ElectricDistribution"
        let tierName = "Medium Voltage Radial"

        // Load the utility network.
        utilityNetwork.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Create a default starting location.
                let networkSource = self.utilityNetwork.definition.networkSource(withName: deviceTableName)
                let assetGroup = networkSource?.assetGroup(withName: assetGroupName)
                let assetType = assetGroup?.assetType(withName: assetTypeName)
                self.startingLocation = self.utilityNetwork.createElement(with: assetType!, globalID: globalID!)
                
                // Set the terminal for this location. (For our case, we use the 'Load' terminal.)
                self.startingLocation?.terminal = self.startingLocation?.assetType.terminalConfiguration?.terminals.first(where: { $0.name == "Load" })
                // Get a default trace configuration from a tier to update the UI.
                let domainNetwork = self.utilityNetwork.definition.domainNetwork(withDomainNetworkName: domainNetworkName)
                self.sourceTier = domainNetwork?.tier(withName: tierName)
                
                // Set the trace configuration.
                self.configuration = self.sourceTier?.traceConfiguration
                
                //Set the default expression (if provided).
                if let expression = self.sourceTier?.traceConfiguration?.traversability?.barriers as? AGSUtilityTraceConditionalExpression {
                    self.textView?.text = self.expressionToString(expression: expression)
                    self.initialExpression = expression
                }
                // Set the traversability scope.
                self.sourceTier?.traceConfiguration?.traversability?.scope = .junctions
            }
        }
    }
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
        if cell == attributesCell {
            // Get the network attributes.
            let attributes = utilityNetwork.definition.networkAttributes.filter { !$0.isSystemDefined }
            // Create the attribute labels.
            let attributeLabels = attributes.map { $0.name }
            // Prompt attribute selection.
            let selectedIndex = selectedAttribute.flatMap { attributes.firstIndex(of: $0) } ?? -1
            let optionsViewController = OptionsTableViewController(labels: attributeLabels, selectedIndex: selectedIndex) { (index) in
                self.selectedAttribute = attributes[index]
                self.attributeLabel?.text = self.selectedAttribute?.name
            }
            optionsViewController.title = "Attributes"
            show(optionsViewController, sender: self)
        } else if cell == comparisonCell {
            // Prompt comparison operator selection.
            let selectedIndex = selectedComparison.flatMap { comparisons.firstIndex(of: $0) } ?? -1
            let optionsViewController = OptionsTableViewController(labels: comparisonsStrings, selectedIndex: selectedIndex) { (index) in
                self.selectedComparison = self.comparisons[index]
                self.comparisonLabel?.text = self.comparisonsStrings[index]
            }
            optionsViewController.title = "Comparison"
            show(optionsViewController, sender: self)
        } else if cell == valueCell {
            if selectedAttribute != nil {
                if let domain = selectedAttribute?.domain as? AGSCodedValueDomain {
                    // Get the value labels.
                    if valueLabels.isEmpty {
                        domain.codedValues.forEach { (codedValue) in
                            valueLabels.append(codedValue.name)
                        }
                    }
                    // Prompt value selection.
                    let selectedIndex = selectedValue.flatMap { domain.codedValues.firstIndex(of: $0 as! AGSCodedValue) } ?? -1
                    let optionsViewController = OptionsTableViewController(labels: valueLabels, selectedIndex: selectedIndex) { (index) in
                        self.valueLabel?.text = self.valueLabels[index]
                        self.selectedValue = domain.codedValues[index]
                    }
                    optionsViewController.title = "Value"
                    show(optionsViewController, sender: self)
                } else {
                    // Prompt the user to create a custom value if none are available to select.
                    addCustomValue()
                }
            }
        } else if cell == addConditionButton {
            addCondition()
        } else if cell == resetButton {
            reset()
        } else if cell == traceButton {
            trace()
        }
    }
    
    func addCustomValue() {
        // Create an alert controller.
        let alert = UIAlertController(title: "Create a value", message: "This attribute has no values. Please create one.", preferredStyle: .alert)
        // Add a "done" button and obtain user input.
        let doneAction = UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            let textfield = alert.textFields![0]
            // Check for invalid input characters.
            if !(CharacterSet(charactersIn: ".-0123456789").isSuperset(of: CharacterSet(charactersIn: textfield.text!))) {
                // Present alert to explain error.
                self?.presentAlert(title: "This field accepts only numeric entries.")
            } else {
                guard let self = self else { return }
                self.valueLabel?.text = textfield.text
                self.tableView.reloadRows(at: [IndexPath(row: 3, section: 1)], with: .none)
                self.selectedValue = textfield.text
            }
        }
        alert.addAction(doneAction)
        doneAction.isEnabled = false
        // Add the text field.
        alert.addTextField { (textField) in
            textField.placeholder = "Add a custom value"
            textField.keyboardType = .numbersAndPunctuation
            textField.delegate = self
            
            // Add an observer to ensure the user does not input an empty string.
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: OperationQueue.main, using: {_ in
                // Get the character count of non-whitespace characters.
                let textCount = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).count ?? 0
                let textIsNotEmpty = textCount > 0
                
                // Enable the done button if the textfield is not empty.
                doneAction.isEnabled = textIsNotEmpty
            })
        }
        // Add cancel button.
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        // Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func addCondition() {
        if configuration == nil {
            configuration = AGSUtilityTraceConfiguration()
        }
        if configuration?.traversability == nil {
            configuration?.traversability = AGSUtilityTraversability()
        }
        // NOTE: You may also create a UtilityCategoryComparison with UtilityNetworkDefinition.Categories and UtilityCategoryComparisonOperator.
        if selectedAttribute != nil {
            // If the value is a coded value.
            if let codedValue = selectedValue as? AGSCodedValue, selectedAttribute?.domain is AGSCodedValueDomain {
                selectedValue = convertToDataType(otherValue: codedValue.code!, dataType: selectedAttribute!.dataType)
            } else {
                selectedValue = convertToDataType(otherValue: selectedValue!, dataType: selectedAttribute!.dataType)
            }
            // NOTE: You may also create a UtilityNetworkAttributeComparison with another NetworkAttribute.
            var expression: AGSUtilityTraceConditionalExpression?
            expression = AGSUtilityNetworkAttributeComparison(networkAttribute: selectedAttribute!, comparisonOperator: selectedComparison!, value: selectedValue!)
            if let otherExpression = configuration?.traversability?.barriers as? AGSUtilityTraceConditionalExpression {
                // NOTE: You may also combine expressions with UtilityTraceAndCondition
                expression = AGSUtilityTraceOrCondition(leftExpression: otherExpression, rightExpression: expression!)
            }
            // Update the list of barrier conditions.
            configuration?.traversability?.barriers = expression
            let expressionString = expressionToString(expression: expression!)
            textView?.text += "\n \(expressionString!))"
        }
    }
    
    func reset() {
        // Reset the barrier condition to the initial value.
        let traceConfiguration = configuration
        traceConfiguration?.traversability?.barriers = initialExpression
        textView?.text = expressionToString(expression: initialExpression!)
        // Reset the selected values.
        selectedAttribute = nil
        selectedComparison = nil
        selectedValue = nil
        //Reset the labels.
        attributeLabel.text = nil
        comparisonLabel.text = nil
        valueLabel.text = nil
    }
    
    func trace() {
        if startingLocation == nil {
            presentAlert(title: "Error", message: "Could not trace utility network.")
        } else {
            // Create utility trace parameters for the starting location.
            let startingLocations = [startingLocation]
            let parameters = AGSUtilityTraceParameters(traceType: .subnetwork, startingLocations: startingLocations as! [AGSUtilityElement])
            parameters.traceConfiguration = configuration
            // Trace the utility network.
            utilityNetwork.trace(with: parameters) { [weak self] (traceResults, error) in
                guard let self = self else { return }
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    // Get the first result.
                    let elementResult = traceResults?.first as! AGSUtilityElementTraceResult
                    // Display the number of elements found by the trace.
                    let numberOfResults = elementResult.elements.count
                    self.presentAlert(title: "Trace Result", message: "\(numberOfResults) elements found.")
                }
            }
        }
    }
    
    func updateButtons() {
        if selectedAttribute == nil || selectedComparison == nil || selectedValue == nil {
            // Enable or disable the value button.
            if selectedAttribute == nil {
                valueButton.isEnabled = false
                valueCell.isUserInteractionEnabled = false
            } else {
                if (selectedAttribute?.domain as? AGSCodedValueDomain) != nil {
                    // Indicate that a new view controller will display.
                    valueCell.accessoryType = .disclosureIndicator
                } else {
                    // Indicate that an alert will show.
                    valueCell.accessoryType = .none
                }
                valueButton.isEnabled = true
                valueCell.isUserInteractionEnabled = true
            }
            // If selections have not been made, disable the buttons
            addConditionLabel.isEnabled = false
            resetLabel.isEnabled = false
            traceLabel.isEnabled = false
        } else {
            // Enable the buttons once all selections have been made
            addConditionLabel.isEnabled = true
            resetLabel.isEnabled = true
            traceLabel.isEnabled = true
        }
    }
    
    // Convert the expression into a readable string.
    func expressionToString(expression: AGSUtilityTraceConditionalExpression) -> String? {
        if let categoryComparison = expression as? AGSUtilityCategoryComparison {
            let comparisonOperatorString = categoryComparisonOperators[categoryComparison.comparisonOperator]
            return "`\(categoryComparison.category.name)` \(comparisonOperatorString!)"
        } else if let attributeComparison = expression as? AGSUtilityNetworkAttributeComparison {
            // Check if attribute domain is a coded value domain.
            if let domain = attributeComparison.networkAttribute.domain as? AGSCodedValueDomain {
                // Get the coded value using the the attribute comparison value and attribute data type.
                let dataType = attributeComparison.networkAttribute.dataType
                let attributeValue = convertToDataType(otherValue: attributeComparison.value!, dataType: attributeComparison.networkAttribute.dataType)
                let codedValue = domain.codedValues.first(where: { compare(dataType: dataType, comparee1: $0.code!, comparee2: attributeValue!) })
                let comparisonOperatorString = comparisonsStrings[attributeComparison.comparisonOperator.rawValue]
                return "'\(attributeComparison.networkAttribute.name)' \(comparisonOperatorString) '\(codedValue!.name)'"
            } else {
                if let nameOrValue = attributeComparison.otherNetworkAttribute?.name {
                    let comparisonOperatorString = comparisonsStrings[attributeComparison.comparisonOperator.rawValue]
                    return "`\(attributeComparison.networkAttribute.name)` \(comparisonOperatorString) `\(nameOrValue)`"
                } else if let nameOrValue = attributeComparison.value {
                    let comparisonOperatorString = comparisonsStrings[attributeComparison.comparisonOperator.rawValue]
                    return "`\(attributeComparison.networkAttribute.name)` \(comparisonOperatorString) `\(nameOrValue)`"
                }
            }
        } else if let andCondition = expression as? AGSUtilityTraceAndCondition {
            return "(\(expressionToString(expression: andCondition.leftExpression)!)) AND\n(\(expressionToString(expression: andCondition.rightExpression)!))"
        } else if let orCondition = expression as? AGSUtilityTraceOrCondition {
            return "(\(expressionToString(expression: orCondition.leftExpression)!)) AND\n(\(expressionToString(expression: orCondition.rightExpression)!))"
        }
        return nil
    }
    
    // Convert the values to matching data types.
    func convertToDataType(otherValue: Any, dataType: AGSUtilityNetworkAttributeDataType) -> Any? {
        switch dataType {
        case .boolean:
            return otherValue as! Bool
        case .double:
            if let valueString = otherValue as? String {
                return Double(valueString)
            }
            return otherValue as! Double
        case .float:
            if let valueString = otherValue as? String {
                return Float(valueString)
            }
            return otherValue as! Float
        case .integer:
            if let valueString = otherValue as? String {
                return Int32(valueString)
            }
            return otherValue as! Int32
        default:
            return nil
        }
    }
    
    // Compare two values.
    func compare(dataType: AGSUtilityNetworkAttributeDataType, comparee1: Any, comparee2: Any) -> Bool {
        switch dataType {
        case .boolean:
            return isEqual(type: Bool.self, value1: comparee1, value2: comparee2)
        case .double:
            return isEqual(type: Double.self, value1: comparee1, value2: comparee2)
        case .float:
            return isEqual(type: Float.self, value1: comparee1, value2: comparee2)
        case .integer:
            return isEqual(type: Int32.self, value1: comparee1, value2: comparee2)
        default:
            return false
        }
    }
    
    func isEqual<T: Equatable>(type: T.Type, value1: Any, value2: Any) -> Bool {
        guard let value1 = value1 as? T, let value2 = value2 as? T else { return false }
        return value1 == value2
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadUtilityNetwork()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ConfigureSubnetworkTraceViewController", "OptionsTableViewController"]
    }
}

extension ConfigureSubnetworkTraceViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let validCharacters = ".-0123456789"
        let text = textField.text!

        return CharacterSet(charactersIn: validCharacters).isSuperset(of: CharacterSet(charactersIn: text))
    }
}
