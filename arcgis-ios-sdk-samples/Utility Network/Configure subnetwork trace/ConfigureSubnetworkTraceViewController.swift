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
    
    var expressionLabel: UILabel?
    var utilityNetwork: AGSUtilityNetwork?
    // For creating the default starting location.
    let deviceTableName = "Electric Distribution Device"
    let assetGroupName = "Circuit Breaker"
    let assetTypeName = "Three Phase"
    let globalID = UUID(uuidString: "1CAF7740-0BF4-4113-8DB2-654E18800028")
    // For creating the default trace configuration.
    let domainNetworkName = "ElectricDistribution"
    let tierName = "Medium Voltage Radial"
    var attributes: [AGSUtilityNetworkAttribute]?
    
    // Utility element to start the trace from.
    var startingLocation: AGSUtilityElement?

    // Holding the initial conditional expression.
    var initialExpression: AGSUtilityTraceConditionalExpression?
    
    // The trace configuration.
    var configuration: AGSUtilityTraceConfiguration?

    // The source tier of the utility network.
    var sourceTier: AGSUtilityTier?

//     The currently selected values for the barrier expression.
//    private let selectedAttribute: AGSUtilityNetworkAttribute!
//    private let selectedComparison: AGSUtilityAttributeComparisonOperator!
    
    let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!
    
    func makeUtilityNetwork() {
        utilityNetwork = AGSUtilityNetwork(url: featureServiceURL)
        utilityNetwork?.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.attributes = self.utilityNetwork?.definition.networkAttributes
                let networkSource = self.utilityNetwork?.definition.networkSource(withName: self.deviceTableName)
                let assetGroup = networkSource?.assetGroup(withName: self.assetGroupName)
                let assetType = assetGroup?.assetType(withName: self.assetTypeName)
                self.startingLocation = self.utilityNetwork?.createElement(with: assetType!, globalID: self.globalID!)
                // Set the terminal for this location. (For our case, we use the 'Load' terminal.)
                self.startingLocation?.terminal = self.startingLocation?.assetType.terminalConfiguration?.terminals.first
                // Get a default trace configuration from a tier to update the UI.
                let domainNetwork = self.utilityNetwork?.definition.domainNetwork(withDomainNetworkName: self.domainNetworkName)
                self.sourceTier = domainNetwork?.tier(withName: self.tierName)
                
                // Set the trace configuration.
                self.configuration = self.sourceTier?.traceConfiguration
                
                //Set the default expression (if provided).
                if let expression = self.sourceTier?.traceConfiguration?.traversability?.barriers as? AGSUtilityTraceConditionalExpression {
                    print(self.expressionToString(expression: expression))
                    self.expressionLabel?.text = self.expressionToString(expression: expression)
                    self.initialExpression = expression
                }
                // Set the traversability scope.
                self.sourceTier?.traceConfiguration?.traversability?.scope = AGSUtilityTraversabilityScope.junctions
                // ENABLE USER INTERACTION
                self.performSegue(withIdentifier: "EditConfigurationSegue", sender: self)
            }
        }
    }
    
    func expressionToString(expression: AGSUtilityTraceConditionalExpression) -> String? {
        if let categoryComparison = expression as? AGSUtilityCategoryComparison {
            return "`\(categoryComparison.category.name)` \(categoryComparison.comparisonOperator)"
        } else if let attributeComparison = expression as? AGSUtilityNetworkAttributeComparison {
            // Check if attribute domain is a coded value domain.
            if let domain = attributeComparison.networkAttribute.domain as? AGSCodedValueDomain {
                // Get the coded value using the the attribute comparison value and attribute data type.
                let dataType = attributeComparison.networkAttribute.dataType
                let attributeValue = convertToDataType(otherValue: attributeComparison.value!, dataType: attributeComparison.networkAttribute.dataType)
                let codedValue = domain.codedValues.first(where: { compare(dataType: dataType, comparee1: $0.code!, comparee2: attributeValue!) })
                return "\(attributeComparison.networkAttribute.name) \(attributeComparison.comparisonOperator) \(String(describing: codedValue?.name))"
            } else {
                if let nameOrValue = attributeComparison.otherNetworkAttribute?.name {
                    return "`\(attributeComparison.networkAttribute.name)` \(attributeComparison.comparisonOperator) `\(nameOrValue)`"
                } else if let nameOrValue = attributeComparison.value {
                    return "`\(attributeComparison.networkAttribute.name)` \(attributeComparison.comparisonOperator) `\(nameOrValue)`"
                }
            }
        } else if let andCondition = expression as? AGSUtilityTraceAndCondition {
            return "(\(String(describing: expressionToString(expression: andCondition.leftExpression))) AND\n(\(String(describing: expressionToString(expression: andCondition.rightExpression)))"
        } else if let orCondition = expression as? AGSUtilityTraceOrCondition {
            return "(\(String(describing: expressionToString(expression: orCondition.leftExpression))) AND\n(\(String(describing: expressionToString(expression: orCondition.rightExpression)))"
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
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ConfigureSubnetworkTraceViewController", "ConfigureSubnetworkTraceConfigurationsViewController", "OptionsTableViewController"]
        makeUtilityNetwork()
        // initially show the map creation UI
//        performSegue(withIdentifier: "EditConfigurationSegue", sender: self)
    }
    
    // MARK: - Navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            super.prepare(for: segue, sender: sender)
            if let navController = segue.destination as? UINavigationController,
                let controller = navController.topViewController as? ConfigureSubnetworkTraceConfigurationsViewController {
                controller.sourceTier = self.sourceTier
                controller.configuration = self.configuration!
                controller.attributes = (self.attributes?.filter { $0.isSystemDefined == false })!
            }
        }
    
    // MARK: - CreateOptionsViewControllerDelegate
    
//    func configureSubnetworkTraceConfigurationsViewController() {
//        makeUtilityNetwork()
//        configureSubnetworkTraceConfigurationsViewController.dismiss(animated: true)
//    }
}
