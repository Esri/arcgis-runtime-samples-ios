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

class ConfigureSubnetworkTraceConfigurationsViewController: UITableViewController {
    @IBOutlet weak var barriersSwitch: UISwitch?
    @IBOutlet weak var containersSwitch: UISwitch?
    @IBOutlet weak var attributesCell: UITableViewCell?
    @IBOutlet weak var comparisonCell: UITableViewCell?
    @IBOutlet weak var valueCell: UITableViewCell?
    @IBOutlet weak var attributeLabel: UILabel?
    @IBOutlet weak var comparisonLabel: UILabel?
    @IBOutlet weak var valueLabel: UILabel?
    @IBOutlet weak var addConditionButton: UITableViewCell?
//    @IBOutlet weak var traceButton: UITableViewCell?
    @IBOutlet weak var textView: UITextView?
    
    @IBAction func barriersSwitchAction(_ sender: UISwitch) {
        sourceTier?.traceConfiguration?.includeBarriers = sender.isOn
    }
    @IBAction func containersSwitchAction(_ sender: UISwitch) {
        sourceTier?.traceConfiguration?.includeContainers = sender.isOn
    }
    @IBAction func resetButton() {
        // Reset the barrier condition to the initial value.
        let traceConfiguration = configuration
        traceConfiguration?.traversability?.barriers = initialExpression
        textView?.text = controller.expressionToString(expression: initialExpression!)
    }
    @IBAction func traceAction() {
        if utilityNetwork == nil || startingLocation == nil {
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
                    
                    // Display the number of elements found by the trace.
                    self.presentAlert(title: "Trace Result", message: "\(elementResult.elements.count) elements found.")
                }
            }
        }
    }

    let controller = ConfigureSubnetworkTraceViewController()
    var initialExpression: AGSUtilityTraceConditionalExpression?
    var utilityNetwork: AGSUtilityNetwork?
    var startingLocation: AGSUtilityElement?
    var configuration: AGSUtilityTraceConfiguration?
    var sourceTier: AGSUtilityTier?
    var attributes: [AGSUtilityNetworkAttribute]?
    var comparisons: [AGSUtilityAttributeComparisonOperator]?
    var values: [AGSCodedValue]?
    var selectedAttribute: AGSUtilityNetworkAttribute?
    var selectedComparison: AGSUtilityAttributeComparisonOperator?
    var selectedValue: Any?
    var selectedValueString: String?
    var attributeLabels: [String] = []
    var valueLabels: [String] = []
    let comparisonsStrings = ["Equal", "NotEqual", "GreaterThan", "GreaterThanEqual", "LessThan", "LessThanEqual", "IncludesTheValues", "DoesNotIncludeTheValues", "IncludesAny", "DoesNotIncludeAny"]
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        attributes?.forEach { (attribute) in
            attributeLabels.append(attribute.name)
        }
        let cell = tableView.cellForRow(at: indexPath)
        if cell == attributesCell {
            let optionsViewController = OptionsTableViewController(labels: attributeLabels, selectedIndex: attributes!.count) { (newIndex) in
                self.selectedAttribute = self.attributes?[newIndex]
                self.attributeLabel?.text = self.selectedAttribute?.name
            }
            optionsViewController.title = "Attributes"
            show(optionsViewController, sender: self)
        } else if cell == comparisonCell {
            let optionsViewController = OptionsTableViewController(labels: comparisonsStrings, selectedIndex: comparisonsStrings.count) { (newIndex) in
                self.selectedComparison = self.comparisons?[newIndex]
                self.comparisonLabel?.text = self.comparisonsStrings[newIndex]
            }
            optionsViewController.title = "Comparison"
            show(optionsViewController, sender: self)
        } else if cell == valueCell {
            if selectedAttribute != nil {
                if let domain = selectedAttribute?.domain as? AGSCodedValueDomain {
                    if valueLabels.isEmpty {
                        print("isEMPTY")
                        domain.codedValues.forEach { (codedValue) in
                            valueLabels.append(codedValue.name)
                        }
                    }
                    print("num of codedVals \(domain.codedValues.count)")
                    print(valueLabels)
                    let optionsViewController = OptionsTableViewController(labels: valueLabels, selectedIndex: domain.codedValues.count) { (newIndex) in
                        self.valueLabel?.text = self.valueLabels[newIndex]
                        self.selectedValue = domain.codedValues[newIndex]
                    }
                    optionsViewController.title = "Value"
                    show(optionsViewController, sender: self)
                }
            } else {
                print("selectedAttribute is nil")
            }
        } else if cell == addConditionButton {
            if configuration == nil {
                configuration = AGSUtilityTraceConfiguration()
            }
            if configuration?.traversability == nil {
                configuration?.traversability = AGSUtilityTraversability()
            }
            // NOTE: You may also create a UtilityCategoryComparison with UtilityNetworkDefinition.Categories and UtilityCategoryComparisonOperator.
            if selectedAttribute != nil {
                var selectedValue: Any?
                // If the value is a coded value.
                if let codedValue = selectedValue as? AGSCodedValue, selectedAttribute?.domain is AGSCodedValueDomain {
                    selectedValue = controller.convertToDataType(otherValue: codedValue.code!, dataType: selectedAttribute!.dataType)
                } else {
                    selectedValue = controller.convertToDataType(otherValue: selectedValueString!, dataType: selectedAttribute!.dataType)
                }
                // NOTE: You may also create a UtilityNetworkAttributeComparison with another NetworkAttribute.
                var expression: AGSUtilityTraceConditionalExpression?
                expression = AGSUtilityNetworkAttributeComparison(networkAttribute: selectedAttribute!, comparisonOperator: selectedComparison!, value: selectedValue!)
                if let otherExpression = configuration?.traversability?.barriers as? AGSUtilityTraceConditionalExpression {
                    // NOTE: You may also combine expressions with UtilityTraceAndCondition
                    expression = AGSUtilityTraceOrCondition(leftExpression: otherExpression, rightExpression: expression!)
                }
                configuration?.traversability?.barriers = expression
                let expressionString = controller.expressionToString(expression: expression!)
                textView?.text += "\n \(String(describing: expressionString))"
            }
        }
    }
}
