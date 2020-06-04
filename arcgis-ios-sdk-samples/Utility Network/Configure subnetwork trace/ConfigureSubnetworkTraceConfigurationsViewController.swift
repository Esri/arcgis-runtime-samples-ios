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
    @IBOutlet weak var addConditionButton: UITableViewCell?
    
    @IBAction func barriersSwitchAction(_ sender: UISwitch) {
        sourceTier?.traceConfiguration?.includeBarriers = sender.isOn
    }
    @IBAction func containersSwitchAction(_ sender: UISwitch) {
        sourceTier?.traceConfiguration?.includeContainers = sender.isOn
    }
    
    var configuration: AGSUtilityTraceConfiguration?
    var sourceTier: AGSUtilityTier?
    var attributes: [AGSUtilityNetworkAttribute]
    var comparisons: [AGSUtilityAttributeComparisonOperator]
    var values: [AGSCodedValue]
    var selectedAttribute: AGSUtilityNetworkAttribute?
    var selectedComparison: AGSUtilityAttributeComparisonOperator?
    var selectedValue: Any?
    var selectedValueString: String?
    var attributeLabels: [String]?
    var valueLabels: [String]?
    let comparisonsStrings = ["Equal", "NotEqual", "GreaterThan", "GreaterThanEqual", "LessThan", "LessThanEqual", "IncludesTheValues", "DoesNotIncludeTheValues", "IncludesAny", "DoesNotIncludeAny"]
    
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
    
    /// MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        for attribute in attributes {
            attributeLabels?.append(attribute.name)
        }
        
        let cell = tableView.cellForRow(at: indexPath)
        if cell == attributesCell {
            let optionsViewController = OptionsTableViewController(labels: attributeLabels!, selectedIndex: attributes.hashValue + 1) { (newIndex) in
                self.selectedAttribute = self.attributes[newIndex - 1]
            }
            optionsViewController.title = "Attributes"
            show(optionsViewController, sender: self)
        } else if cell == comparisonCell {
            let optionsViewController = OptionsTableViewController(labels: comparisonsStrings, selectedIndex: comparisonsStrings.hashValue + 1) { (newIndex) in
                self.selectedComparison = self.comparisons[newIndex-1]
            }
            optionsViewController.title = "Comparison"
            show(optionsViewController, sender: self)
        } else if cell == valueCell {
            if selectedAttribute != nil {
                if let domain = selectedAttribute?.domain as? AGSCodedValueDomain {
                    for value in domain.codedValues {
                        valueLabels?.append(value.name)
                    }
                    let optionsViewController = OptionsTableViewController(labels: valueLabels!, selectedIndex: domain.codedValues.hashValue + 1) { (newIndex) in
                        self.selectedValueString = self.valueLabels?[newIndex - 1]
                        self.selectedValue = domain.codedValues[newIndex - 1]
                    }
                    optionsViewController.title = "Value"
                    show(optionsViewController, sender: self)
                }
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
                    selectedValue = convertToDataType(otherValue: codedValue.code!, dataType: selectedAttribute!.dataType)
                } else {
                    selectedValue = convertToDataType(otherValue: selectedValueString!, dataType: selectedAttribute!.dataType)
                }
                // NOTE: You may also create a UtilityNetworkAttributeComparison with another NetworkAttribute.
                var expression = AGSUtilityNetworkAttributeComparison(networkAttribute: selectedAttribute!, comparisonOperator: selectedComparison!, value: selectedValue!)
                if let otherExpression = configuration?.traversability?.barriers as? AGSUtilityTraceConditionalExpression {
                    // NOTE: You may also combine expressions with UtilityTraceAndCondition
                    expression = AGSUtilityTraceOrCondition(leftExpression: otherExpression, rightExpression: expression!)
                }
                configuration?.traversability?.barriers = expression
//                expressionLabel.Text =
            }
        }
    }
}
