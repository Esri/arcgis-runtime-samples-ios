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
    
    private var configuration: AGSUtilityTraceConfiguration?
    private let selectedAttribute: AGSUtilityNetworkAttribute?
    
    /// MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        if cell == attributesCell {
            let optionsViewController = OptionsTableViewController(labels: slopeTypeLabels, selectedIndex: slopeType.rawValue + 1) { (newIndex) in
                self.slopeType = AGSSlopeType(rawValue: newIndex - 1)!
                self.blendRendererParametersChanged()
            }
            optionsViewController.title = "Attributes"
            show(optionsViewController, sender: self)
        } else if cell == comparisonCell {
            let optionsViewController = OptionsTableViewController(labels: colorRampLabels, selectedIndex: colorRampType.rawValue + 1) { (newIndex) in
                self.colorRampType = AGSPresetColorRampType(rawValue: newIndex - 1)!
                self.blendRendererParametersChanged()
            }
            optionsViewController.title = "Comparison"
            show(optionsViewController, sender: self)
        } else if cell == valueCell {
            let optionsViewController = OptionsTableViewController(labels: colorRampLabels, selectedIndex: colorRampType.rawValue + 1) { (newIndex) in
                self.colorRampType = AGSPresetColorRampType(rawValue: newIndex - 1)!
                self.blendRendererParametersChanged()
            }
            optionsViewController.title = "Value"
            show(optionsViewController, sender: self)
        } else if cell == addConditionButton {
            if configuration == nil {
                configuration = AGSUtilityTraceConfiguration()
            }
            if configuration.traversability == nil {
                configuration.traversability = AGSUtilityTraversability()
            }
            // NOTE: You may also create a UtilityCategoryComparison with UtilityNetworkDefinition.Categories and UtilityCategoryComparisonOperator.
            if selectedAttribute != nil {
                var selectedValue: Any?
                // If the value is a coded value.
                if let codedValue = selectedValue as? AGSCodedValue, selectedAttribute?.domain is AGSCodedValueDomain {
                    selectedValue = convertTo
                } else {
                    selectedValue = convertTo
                }
                // NOTE: You may also create a UtilityNetworkAttributeComparison with another NetworkAttribute.
                let expression = AGSUtilityNetworkAttributeComparison(networkAttribute: selectedAttribute, comparisonOperator: selectedComparison, value: selectedValue)
                if let otherExpression = configuration?.traversability?.barriers as? AGSUtilityTraceConditionalExpression {
                    // NOTE: You may also combine expressions with UtilityTraceAndCondition
                    expression = AGSUtilityTraceOrCondition(leftExpression: otherExpression, rightExpression: expression)
                }
                configuration?.traversability?.barriers = expression
                expressionLabel.Text = 
            }
        }
    }
}
