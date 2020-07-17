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
//    @IBOutlet weak var attributesCell: UITableViewCell!
//    @IBOutlet weak var comparisonCell: UITableViewCell!
//    @IBOutlet weak var valueCell: UITableViewCell!
    weak var addConditionLabel: UILabel?
    weak var resetLabel: UILabel?
    weak var traceLabel: UILabel?
    // References to labels.
//    @IBOutlet weak var attributeLabel: UILabel!
//    @IBOutlet weak var comparisonLabel: UILabel!
    @IBOutlet weak var valueButton: UILabel!
//    @IBOutlet weak var valueLabel: UILabel!
    // References to cells that act as buttons.
    weak var addConditionCell: UITableViewCell?
    weak var resetCell: UITableViewCell?
    weak var traceCell: UITableViewCell?
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
//    var expressionString: String?
    // The trace configuration.
    var configuration: AGSUtilityTraceConfiguration?
    // The source tier of the utility network.
    var sourceTier: AGSUtilityTier?
    // The number of added conditions.
    var numberOfConditions = 1
    // Arrays of attributes, values, and their respective labels.
    var valueLabels: [String] = []
    // The attribute selected by the user.
    var selectedAttribute: AGSUtilityNetworkAttribute? {
        didSet {
            // Reset the selected value.
            selectedValue = nil
            valueLabel?.text = ""
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
    
    var valueCell: UITableViewCell?
    var attributeLabel: UILabel?
    var comparisonLabel: UILabel?
    var valueLabel: UILabel?
    
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
                    self.initialExpression = expression
                    let indexPath = IndexPath(row: 0, section: 2)
                    let cell = self.tableView.cellForRow(at: indexPath)
//                    print(self.expressionToString(expression: expression))
                    cell?.textLabel?.text = self.expressionToString(expression: expression)
//                    self.tableView.reloadRows(at: [indexPath], with: .none)
//                    self.tableView.performBatchUpdates({
//                        // insert the new row
//                        let indexPath = IndexPath(row: 0, section: 2)
//                        self.tableView.insertRows(at: [indexPath], with: .fade)
//                        self.tableView.moveRow(at: indexPath, to: IndexPath(row: 1, section: 2))
//                        let cell = self.tableView.cellForRow(at: indexPath)
//                        cell?.textLabel?.text = self.expressionToString(expression: expression)
//                    }, completion: nil)
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
        if indexPath == IndexPath(row: 0, section: 1) {
            // Get the network attributes.
            let attributes = utilityNetwork.definition.networkAttributes.filter { !$0.isSystemDefined }
            // Create the attribute labels.
            let attributeLabels = attributes.map { $0.name }
            // Prompt attribute selection.
            let selectedIndex = selectedAttribute.flatMap { attributes.firstIndex(of: $0) } ?? -1
            let optionsViewController = OptionsTableViewController(labels: attributeLabels, selectedIndex: selectedIndex) { (index) in
                self.selectedAttribute = attributes[index]
                self.attributeLabel?.text = self.selectedAttribute?.name
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
            }
            optionsViewController.title = "Attributes"
            show(optionsViewController, sender: self)
        } else if indexPath == IndexPath(row: 1, section: 1) {
            // Prompt comparison operator selection.
            let selectedIndex = selectedComparison.flatMap { comparisons.firstIndex(of: $0) } ?? -1
            let optionsViewController = OptionsTableViewController(labels: comparisonsStrings, selectedIndex: selectedIndex) { (index) in
                self.selectedComparison = self.comparisons[index]
                self.comparisonLabel?.text = self.comparisonsStrings[index]
            }
            optionsViewController.title = "Comparison"
            show(optionsViewController, sender: self)
        } else if indexPath == IndexPath(row: 2, section: 1) {
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
        } else if indexPath == IndexPath(row: 3, section: 1) {
            addCondition()
        } else if indexPath == IndexPath(row: numberOfConditions, section: 2) {
            reset()
        } else if indexPath == IndexPath(row: numberOfConditions + 1, section: 2) {
            trace()
        }
    }
    
    func addCustomValue() {
        // Create an alert controller.
        let alert = UIAlertController(title: "Create a value", message: "This attribute has no values. Please create one.", preferredStyle: .alert)
        // Add a "done" button and obtain user input.
        let doneAction = UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            let textfield = alert.textFields![0]
            guard let self = self else { return }
            self.valueLabel?.text = textfield.text
            self.tableView.reloadRows(at: [IndexPath(row: 3, section: 1)], with: .none)
            self.selectedValue = textfield.text
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
//            textView?.text += """
//
//            \(expressionString!)
//            """
            numberOfConditions += 1
            let newIndexPath = IndexPath(row: numberOfConditions - 1, section: 2)
            // update the table
            tableView.performBatchUpdates({
                // insert the new row
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }, completion: nil)
            let cell = tableView.cellForRow(at: newIndexPath)
            cell?.textLabel?.text = "\(expressionString!)"
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
        attributeLabel?.text = nil
        comparisonLabel?.text = nil
        valueLabel?.text = nil
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
                } else if let elementResult = traceResults?.first as! AGSUtilityElementTraceResult? {
                    // Display the number of elements found by the trace.
                    let numberOfResults = elementResult.elements.count
                    self.presentAlert(title: "Trace Result", message: "\(numberOfResults) elements found.")
                } else {
                    self.presentAlert(title: "Trace Result", message: "No trace results found.")
                }
            }
        }
    }
    
    func updateButtons() {
        if selectedAttribute == nil || selectedComparison == nil || selectedValue == nil {
            guard let valueCell = valueCell else { return }
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
            addConditionLabel?.isEnabled = false
            resetLabel?.isEnabled = false
            traceLabel?.isEnabled = false
        } else {
            // Enable the buttons once all selections have been made
            addConditionLabel?.isEnabled = true
            resetLabel?.isEnabled = true
            traceLabel?.isEnabled = true
        }
    }
    
    // Convert the expression into a readable string.
    func expressionToString(expression: AGSUtilityTraceConditionalExpression) -> String? {
        switch expression {
        case let categoryComparison as AGSUtilityCategoryComparison:
            let comparisonOperatorString = categoryComparisonOperators[categoryComparison.comparisonOperator]
            return "`\(categoryComparison.category.name)` \(comparisonOperatorString!)"
        case let attributeComparison as AGSUtilityNetworkAttributeComparison:
            // Check if attribute domain is a coded value domain.
            if let domain = attributeComparison.networkAttribute.domain as? AGSCodedValueDomain {
                // Get the coded value using the the attribute comparison value and attribute data type.
                let dataType = attributeComparison.networkAttribute.dataType
                let attributeValue = convertToDataType(otherValue: attributeComparison.value!, dataType: attributeComparison.networkAttribute.dataType)
                let codedValue = domain.codedValues.first(where: { compare(dataType: dataType, value1: $0.code!, value2: attributeValue!) })
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
        case let andCondition as AGSUtilityTraceAndCondition:
            return """
            (\(expressionToString(expression: andCondition.leftExpression)!)) AND
            (\(expressionToString(expression: andCondition.rightExpression)!))
            """
            
        case let orCondition as AGSUtilityTraceOrCondition:
            return """
            (\(expressionToString(expression: orCondition.leftExpression)!)) AND
            (\(expressionToString(expression: orCondition.rightExpression)!))
            """
        default:
            return nil
        }
        return nil
    }
    
    // Convert the values to matching data types.
    func convertToDataType(otherValue: Any, dataType: AGSUtilityNetworkAttributeDataType) -> Any? {
        switch dataType {
        case .boolean:
            return otherValue as! Bool
        case .float:
            if let valueString = otherValue as? String {
                return Float(valueString)
            }
            return otherValue as! Float
        case .double:
            if let valueString = otherValue as? String {
                return Double(valueString)
            }
            return otherValue as! Double
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
    func compare(dataType: AGSUtilityNetworkAttributeDataType, value1: Any, value2: Any) -> Bool {
        switch dataType {
        case .boolean:
            return value1 as? Bool == value2 as? Bool
        case .double:
            return value1 as? Double == value2 as? Double
        case .float:
            return value1 as? Float == value2 as? Float
        case .integer:
            return value1 as? Int32 == value2 as? Int32
        default:
            return false
        }
    }
    
    /// A convenience type for the table view sections.
    private enum Section: CaseIterable {
        case switches, newCondition, conditions
        
        var label: String {
            switch self {
            case .switches:
                return "Trace options"
            case .newCondition:
                return "Define new condition"
            case .conditions:
                return "Barrier conditions"
            }
        }
    }
    
    private enum Switches: CaseIterable {
        case barriers, containers
        
        var label: String {
            switch self {
            case .barriers:
                return "Include barriers"
            case .containers:
                return "Include containers"
            }
        }
    }
    
    func assignCellsAndLabels(indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0:
                let attributeCell = tableView.cellForRow(at: indexPath)
                attributeLabel = attributeCell?.detailTextLabel
            case 1:
                let comparisonCell = tableView.cellForRow(at: indexPath)
                comparisonLabel = comparisonCell?.detailTextLabel
            case 2:
                valueCell = tableView.cellForRow(at: indexPath)
                valueLabel = valueCell?.detailTextLabel
            case 3:
                addConditionCell = tableView.cellForRow(at: indexPath)
                addConditionLabel = addConditionCell?.textLabel
            default:
                print("idk")
            }
        case 2:
            switch indexPath.row {
            case numberOfConditions:
                resetCell = tableView.cellForRow(at: indexPath)
                resetLabel = resetCell?.textLabel
            case numberOfConditions + 1:
                traceCell = tableView.cellForRow(at: indexPath)
                traceLabel = traceCell?.textLabel
            default:
                print("idk")
            }
        default:
            print("idk")
        }
    }
    
    let switches = ["Include barriers", "Include containers"]
    let cellIdentifiers = ["SwitchCell", "SelectionCell", "LabelOrConditionCell"]
    let selectionLabels = ["Attribute", "Comparison", "Value", "Add new condition"]
    let conditionLabels = ["Reset", "Trace"]
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .switches:
            return 2
        case .newCondition:
            return 4
        case .conditions:
            return numberOfConditions + 2
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section.allCases[section].label
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        switch Section.allCases[indexPath.section] {
        case .switches:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath)
            cell.textLabel?.text = switches[indexPath.row]
            switch indexPath.row {
            case 0:
                cell.accessoryView = barriersSwitch
            case 1:
                cell.accessoryView = containersSwitch
            default:
                print("idk what to do here hehe")
            }
            return cell
        case .newCondition:
            if indexPath.row < 3 {
                let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath)
                cell.textLabel?.text = selectionLabels[indexPath.row]
                if indexPath.row < 2 {
                    cell.textLabel?.textColor = .systemBlue
                    cell.accessoryType = .disclosureIndicator
                }
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "LabelOrConditionCell", for: indexPath)
                cell.textLabel?.text = selectionLabels[indexPath.row]
                cell.textLabel?.textColor = .systemBlue
                return cell
            }
        case .conditions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "LabelOrConditionCell", for: indexPath)
            if indexPath.row >= numberOfConditions {
                cell.textLabel?.text = conditionLabels[indexPath.row - 1]
                cell.textLabel?.textColor = .systemBlue
//                tableView.numberOfRows(inSection: 2)
            }
            return cell
        }
        assignCellsAndLabels(indexPath: indexPath)
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadUtilityNetwork()
        tableView.dataSource = self
        tableView.delegate = self
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ConfigureSubnetworkTraceViewController", "OptionsTableViewController"]
    }
}

extension ConfigureSubnetworkTraceViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        let validCharacters = ".-0123456789"
        
        return CharacterSet(charactersIn: validCharacters).isSuperset(of: CharacterSet(charactersIn: text))
    }
}
