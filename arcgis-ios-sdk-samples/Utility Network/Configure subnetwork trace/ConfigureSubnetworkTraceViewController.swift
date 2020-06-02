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

class ConfigureSubnetworkTraceViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView!
    
    private var expressionLabel: UILabel?
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
    private var initialExpression: AGSUtilityTraceConditionalExpression?

    // The source tier of the utility network.
    private var sourceTier: AGSUtilityTier?

//     The currently selected values for the barrier expression.
//    private let selectedAttribute: AGSUtilityNetworkAttribute!
//    private let selectedComparison: AGSUtilityAttributeComparisonOperator!
    
    private let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!
    
    func makeUtilityNetwork() {
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
        if let expression = sourceTier?.traceConfiguration?.traversability?.barriers as? AGSUtilityTraceConditionalExpression {
            expressionLabel?.text = expressionToString(expression: expression)
            initialExpression = expression
        }
        // Set the traversability scope.
        sourceTier?.traceConfiguration?.traversability?.scope = AGSUtilityTraversabilityScope.junctions
        // ENABLE USER INTERACTION
    }
    
    func expressionToString(expression: AGSUtilityTraceConditionalExpression) -> String? {
        if let categoryComparison = expression as? AGSUtilityCategoryComparison {
            return "`{categoryComparison.Category.Name}` {categoryComparison.ComparisonOperator}" // MUST FORMAT HERE BUT HOW
        } else if let attributeComparison = expression as? AGSUtilityNetworkAttributeComparison {
            // Check if attribute domain is a coded value domain.
            if let domain = attributeComparison.networkAttribute.domain as? AGSCodedValueDomain {
                // Get the coded value using the the attribute comparison value and attribute data type.
                let dataType = attributeComparison.networkAttribute.dataType
                let attributeValue = convertToDataType(otherValue: attributeComparison.value!, dataType: attributeComparison.networkAttribute.dataType)
                let codedValue = domain.codedValues.first(where: convertToDataType(otherValue: {$0.code}, dataType: dataType) == (attributeValue))
            } else {
                return "`{attributeComparison.NetworkAttribute.Name}` {attributeComparison.ComparisonOperator} `{attributeComparison.OtherNetworkAttribute?.Name ?? attributeComparison.Value}`"
            }
        } else if let andCondition = expression as? AGSUtilityTraceCondition {
            return "({ExpressionToString(andCondition.LeftExpression)}) AND\n ({ExpressionToString(andCondition.RightExpression)})"
        } else if let orCondition = expression as? AGSUtilityTraceCondition {
            return "({ExpressionToString(orCondition.LeftExpression)}) OR\n ({ExpressionToString(orCondition.RightExpression)})"
        } else {
            return nil
        }
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
    
    func equals(a: Any, b: Any) -> Bool {
        if type(of: a) == type(of: b) {
            guard let a = a as? (type(of: a)), let b = b as? (type(of: b)) else { return false }
            return a == b
        } else { return false }
    }
    
    override func viewDidLoad() {
    super.viewDidLoad()
    
    //add the source code button item to the right of navigation bar
    (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ConfigureSubnetworkTraceViewController", "ConfigureSubnetworkTraceConfigurationsViewController", "OptionsTableViewController"]
    }
}
