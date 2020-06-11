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
    @IBOutlet weak var barriersSwitch: UISwitch!
    @IBOutlet weak var containersSwitch: UISwitch!
    @IBOutlet weak var attributesCell: UITableViewCell!
    @IBOutlet weak var comparisonCell: UITableViewCell!
    @IBOutlet weak var valueCell: UITableViewCell!
    @IBOutlet weak var attributeLabel: UILabel!
    @IBOutlet weak var comparisonLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    @IBOutlet weak var addConditionButton: UITableViewCell!
    @IBOutlet weak var resetButton: UITableViewCell!
    @IBOutlet weak var traceButton: UITableViewCell!
    @IBOutlet weak var textView: UITextView!
    
    @IBAction func barriersSwitchAction(_ sender: UISwitch) {
        sourceTier?.traceConfiguration?.includeBarriers = sender.isOn
    }
    @IBAction func containersSwitchAction(_ sender: UISwitch) {
        sourceTier?.traceConfiguration?.includeContainers = sender.isOn
    }
    
    var expressionLabel: UILabel?
    var utilityNetwork: AGSUtilityNetwork?
    let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!
    // For creating the default starting location.
    let deviceTableName = "Electric Distribution Device"
    let assetGroupName = "Circuit Breaker"
    let assetTypeName = "Three Phase"
    let globalID = UUID(uuidString: "1CAF7740-0BF4-4113-8DB2-654E18800028")
    // For creating the default trace configuration.
    let domainNetworkName = "ElectricDistribution"
    let tierName = "Medium Voltage Radial"
    let comparisonsStrings = ["Equal", "NotEqual", "GreaterThan", "GreaterThanEqual", "LessThan", "LessThanEqual", "IncludesTheValues", "DoesNotIncludeTheValues", "IncludesAny", "DoesNotIncludeAny"]
//    let comparisonsDictionary: [AGSUtilityAttributeComparisonOperator: String] = [.equal: "Equal", .notEqual: "NotEqual", .greaterThan: "GreaterThan", .greaterThanEqual: "GreaterThanEqual", .lessThan: "LessThan", .lessThanEqual: "LessThanEqual", .includesTheValues: "IncludesTheValues", .doesNotIncludeTheValues: "DoesNotIncludeTheValues", .includesAny: "IncludesAny", .doesNotIncludeAny: "DoesNotIncludeAny"]
    
    // Utility element to start the trace from.
    var startingLocation: AGSUtilityElement!

    // Holding the initial conditional expression.
    var initialExpression: AGSUtilityTraceConditionalExpression?
    
    // The trace configuration.
    var configuration: AGSUtilityTraceConfiguration?

    // The source tier of the utility network.
    var sourceTier: AGSUtilityTier?
    
    var comparisons: [AGSUtilityAttributeComparisonOperator] = [.equal, .notEqual, .greaterThan, .greaterThanEqual, .lessThan, .lessThanEqual, .includesTheValues, .doesNotIncludeTheValues, .includesAny, .doesNotIncludeAny]
    var values: [AGSCodedValue]?
    var selectedAttribute: AGSUtilityNetworkAttribute?
    var selectedComparison: AGSUtilityAttributeComparisonOperator?
    var selectedValue: Any?
    var selectedValueString: String?
    var attributes: [AGSUtilityNetworkAttribute]?
    var attributeLabels: [String] = []
    var valueLabels: [String] = []
    
    func makeUtilityNetwork() {
        utilityNetwork = AGSUtilityNetwork(url: featureServiceURL)
        utilityNetwork?.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.attributes = self.utilityNetwork?.definition.networkAttributes.filter { $0.isSystemDefined == false }
                let networkSource = self.utilityNetwork?.definition.networkSource(withName: self.deviceTableName)
                let assetGroup = networkSource?.assetGroup(withName: self.assetGroupName)
                let assetType = assetGroup?.assetType(withName: self.assetTypeName)
                self.startingLocation = self.utilityNetwork?.createElement(with: assetType!, globalID: self.globalID!)
                // Set the terminal for this location. (For our case, we use the 'Load' terminal.)
                self.startingLocation?.terminal = self.startingLocation?.assetType.terminalConfiguration?.terminals.first(where: { $0.name == "Load" })
                // Get a default trace configuration from a tier to update the UI.
                let domainNetwork = self.utilityNetwork?.definition.domainNetwork(withDomainNetworkName: self.domainNetworkName)
                self.sourceTier = domainNetwork?.tier(withName: self.tierName)
                
                // Set the trace configuration.
                self.configuration = self.sourceTier?.traceConfiguration
                
                //Set the default expression (if provided).
                if let expression = self.sourceTier?.traceConfiguration?.traversability?.barriers as? AGSUtilityTraceConditionalExpression {
                    print(self.expressionToString(expression: expression)!)
                    self.expressionLabel?.text = self.expressionToString(expression: expression)
                    self.initialExpression = expression
                }
                // Set the traversability scope.
                self.sourceTier?.traceConfiguration?.traversability?.scope = AGSUtilityTraversabilityScope.junctions
            }
        }
    }
        
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if cell == attributesCell {
            if attributeLabels.isEmpty {
                attributes?.forEach { (attribute) in
                    attributeLabels.append(attribute.name)
                }
            }
            let optionsViewController = OptionsTableViewController(labels: attributeLabels, selectedIndex: attributes!.count) { (index) in
                self.selectedAttribute = self.attributes![index]
                self.attributeLabel?.text = self.selectedAttribute?.name
            }
            optionsViewController.title = "Attributes"
            show(optionsViewController, sender: self)
        } else if cell == comparisonCell {
            let optionsViewController = OptionsTableViewController(labels: comparisonsStrings, selectedIndex: comparisonsStrings.count) { (index) in
                self.selectedComparison = self.comparisons[index]
                self.comparisonLabel?.text = self.comparisonsStrings[index]
            }
            optionsViewController.title = "Comparison"
            show(optionsViewController, sender: self)
        } else if cell == valueCell {
            if selectedAttribute != nil {
                if let domain = selectedAttribute?.domain as? AGSCodedValueDomain {
                    if valueLabels.isEmpty {
                        domain.codedValues.forEach { (codedValue) in
                            valueLabels.append(codedValue.name)
                        }
                    }
                    let optionsViewController = OptionsTableViewController(labels: valueLabels, selectedIndex: domain.codedValues.count) { (index) in
                        self.valueLabel?.text = self.valueLabels[index]
                        self.selectedValue = domain.codedValues[index]
                    }
                    optionsViewController.title = "Value"
                    show(optionsViewController, sender: self)
                } else {
                    addCustomValue()
                }
            }
        } else if cell == addConditionButton {
            tableView.deselectRow(at: indexPath, animated: true)
            addCondition()
        } else if cell == resetButton {
            tableView.deselectRow(at: indexPath, animated: true)
            reset()
        } else if cell == traceButton {
            tableView.deselectRow(at: indexPath, animated: true)
            trace()
        }
    }
    
    func addCustomValue() {
        // Create an alert controller.
        let alert = UIAlertController(title: "Create a value", message: "This attribute has no values. Please create one.", preferredStyle: .alert)
        // Add the text field.
        alert.addTextField { (textField) in
            textField.text = "New value"
        }
        // Obtain user value.
        alert.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            let textfield = alert.textFields![0]
            self?.valueLabel?.text = textfield.text
            self?.tableView.reloadRows(at: [IndexPath(row: 3, section: 1)], with: .none)
            self?.selectedValue = textfield.text
        })
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
        selectedAttribute = nil
        selectedComparison = nil
        selectedValue = nil
        attributeLabel.text = nil
        comparisonLabel.text = nil
        valueLabel.text = nil
    }
    
    func trace() {
        if utilityNetwork == nil || startingLocation == nil {
            if utilityNetwork == nil {
                print("UTILITY NETWORK")
            } else if startingLocation == nil {
                print("STARTING LOCATION")
            }
            presentAlert(title: "Error", message: "Could not trace utility network.")
            return
        } else {
            // Create utility trace parameters for the starting location.
            let startingLocations = [startingLocation]
            let parameters = AGSUtilityTraceParameters(traceType: .subnetwork, startingLocations: startingLocations as! [AGSUtilityElement])
            parameters.traceConfiguration = configuration
            // Trace the utility network.
            utilityNetwork?.trace(with: parameters) { [weak self] (traceResults, error) in
                guard let self = self else { return }
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    // Get the first result.
                    let elementResult = traceResults?.first as! AGSUtilityElementTraceResult
                    
                    //dismiss view controller
                    self.dismiss(animated: true)
                    
                    self.showResults(numberOfResults: elementResult.elements.count)
                }
            }
        }
    }
    
    func expressionToString(expression: AGSUtilityTraceConditionalExpression) -> String? {
        if let categoryComparison = expression as? AGSUtilityCategoryComparison {
            let comparisonOperator = AGSUtilityCategoryComparisonOperator.doesNotExist
            return "`\(categoryComparison.category.name)` \(comparisonOperator)"
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
    
    func convertToDataType(otherValue: Any, dataType: AGSUtilityNetworkAttributeDataType) -> Any? {
        switch dataType {
        case .boolean:
            return otherValue as! Bool
        case .double:
            return otherValue as! Double
        case .float:
            return otherValue as! Float
        case .integer:
            return otherValue as! Int32
        default:
            return nil
        }
    }
    
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
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ConfigureSubnetworkTraceViewController", "OptionsTableViewController"]
        makeUtilityNetwork()
    }
    
    func showResults(numberOfResults: Int) {
        // Display the number of elements found by the trace.
        self.presentAlert(title: "Trace Result", message: "\(numberOfResults) elements found.")
    }
}
