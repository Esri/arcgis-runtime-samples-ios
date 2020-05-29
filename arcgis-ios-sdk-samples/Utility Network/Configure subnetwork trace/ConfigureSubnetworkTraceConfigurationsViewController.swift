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
    var expressionLabel: UILabel?
    private var utilityNetwork: AGSUtilityNetwork?
    // For creating the default starting location.
    private let deviceTableName = "Electric Distribution Device"
    private let assetGroupName = "Circuit Breaker"
    private let assetTypeName = "Three Phase"
    private let GUID = "{1CAF7740-0BF4-4113-8DB2-654E18800028}"
    // For creating the default trace configuration.
    private let domainNetworkName = "ElectricDistribution"
    private let tierName = "Medium Voltage Radial"
    
    // Utility element to start the trace from.
    private var startingLocation: AGSUtilityElement?

    // Holding the initial conditional expression.
    private let initialExpression: AGSUtilityTraceConditionalExpression? // Causes error

    // The trace configuration.
    private var configuration: AGSUtilityTraceConfiguration? // Causes error

    // The source tier of the utility network.
    private var sourceTier: AGSUtilityTier? // Causes error

//     The currently selected values for the barrier expression.
//    private let selectedAttribute: AGSUtilityNetworkAttribute?
//    private let selectedComparison: AGSUtilityAttributeComparisonOperator?
    
    private let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!
//    private object selectedValue =
    
    func main() {
        utilityNetwork = AGSUtilityNetwork(url: featureServiceURL)
        let networkSource = utilityNetwork?.definition.networkSource(withName: deviceTableName)
        let assetGroup = networkSource?.assetGroup(withName: assetGroupName)
        let assetType = assetGroup?.assetType(withName: assetTypeName)
        let globalID = UUID.init(uuidString: GUID)
        startingLocation = utilityNetwork?.createElement(with: assetType!, globalID: globalID!)
        // Set the terminal for this location. (For our case, we use the 'Load' terminal.)
        startingLocation?.terminal = startingLocation?.assetType.terminalConfiguration?.terminals.first
        // Get a default trace configuration from a tier to update the UI.
        let domainNetwork = utilityNetwork?.definition.domainNetwork(withDomainNetworkName: domainNetworkName)
        sourceTier = domainNetwork?.tier(withName: tierName)
        
        // Set the trace configuration.
        configuration = sourceTier?.traceConfiguration
        
        //Set the default expression (if provided).
        if let expression = sourceTier?.traceConfiguration?.traversability?.barriers {
            expressionLabel?.text = expression
            
        }
    }
    
    func expressionToString(expression: AGSUtilityTraceConditionalExpression) {
        if let categoryComparison = expression as! AGSUtilityCategoryComparison{
            
        }
    }
    
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
        }
    }
}
