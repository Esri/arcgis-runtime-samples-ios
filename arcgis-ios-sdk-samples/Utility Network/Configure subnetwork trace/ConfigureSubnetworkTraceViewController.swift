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
    // MARK: Storyboard views
    
    /// A label to display chained condtional expressions.
    @IBOutlet var chainedConditionsLabel: UILabel!
    /// A custom view as the table footer view.
    @IBOutlet var customFooterView: UIView!
    /// A switch to control whether to include barriers in the trace.
    @IBOutlet var barriersSwitch: UISwitch!
    /// A switch to control whether to include containers in the trace.
    @IBOutlet var containersSwitch: UISwitch!
    /// The table view to display conditional expressions.
    @IBOutlet var tableView: UITableView!
    
    // MARK: Properties
    
    /// A convenience type for the table view sections.
    private enum Section: Int, CaseIterable {
        case switches, conditions
        
        var label: String {
            switch self {
            case .switches:
                return "Trace options"
            case .conditions:
                return "List of conditions"
            }
        }
    }
    
    /// A convenience type for the labels of switches in the table rows.
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
    
    /// A feature service for an electric utility network in Naperville, Illinois.
    let utilityNetwork = AGSUtilityNetwork(url: URL(string: "https://3.82.6.114/server/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!)
    
    /// An array of condition expressions.
    var traceConditionalExpressions = [AGSUtilityTraceConditionalExpression]()
    
    /// The operator to chain conditions together, i.e. `AND` or `OR`.
    /// - Note: You may also combine expressions with `AGSUtilityTraceAndCondition`.
    ///         i.e. `AGSUtilityTraceAndCondition.init`
    let chainExpressionsOperator = AGSUtilityTraceOrCondition.init
    
    /// The utility element to start the trace from.
    var startingLocation: AGSUtilityElement?
    /// The initial conditional expression.
    var initialExpression: AGSUtilityTraceConditionalExpression?
    /// The trace configuration.
    var configuration: AGSUtilityTraceConfiguration?
    /// A chained expression string.
    var expressionString: String {
        if let expression = chainExpressions(using: chainExpressionsOperator, expressions: traceConditionalExpressions) {
            return expressionToString(expression: expression)
        } else {
            return "Expressions failed to convert to string."
        }
    }
    
    // MARK: Actions
    
    @IBAction func traceBarButtonItemTapped(_ sender: UIBarButtonItem) {
        guard let location = startingLocation else { return }
        
        // Create utility trace parameters for the starting location.
        let parameters = AGSUtilityTraceParameters(traceType: .subnetwork, startingLocations: [location])
        if let configuration = configuration {
            configuration.includeBarriers = barriersSwitch.isOn
            configuration.includeContainers = containersSwitch.isOn
            configuration.traversability?.barriers = chainExpressions(using: chainExpressionsOperator, expressions: traceConditionalExpressions)
            parameters.traceConfiguration = configuration
        }
        
        // Trace the utility network.
        SVProgressHUD.show(withStatus: "Tracing…")
        utilityNetwork.trace(with: parameters) { [weak self] (results, error) in
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else if let elementResult = results?.first as? AGSUtilityElementTraceResult {
                // Display the number of elements found by the trace.
                self.presentAlert(title: "Trace Result", message: "\(elementResult.elements.count) element(s) found.")
            } else {
                // No elements found.
                self.presentAlert(title: "Trace Result", message: "No trace results found.")
            }
        }
    }
    
    @IBAction func resetBarButtonItemTapped(_ sender: UIBarButtonItem) {
        // Reset the barrier condition to the initial value.
        configuration?.traversability?.barriers = initialExpression
        // Reset the conditions.
        if let initialExpression = initialExpression {
            // Add back the initial expression.
            traceConditionalExpressions = [initialExpression]
        } else {
            traceConditionalExpressions.removeAll()
        }
        tableView.reloadSections([Section.conditions.rawValue], with: .automatic)
        // Reload footer label.
        chainedConditionsLabel.text = expressionString
    }
    
    // MARK: Methods
    
    func loadUtilityNetwork() {
        // Constants for creating the default starting location.
        let deviceTableName = "Electric Distribution Device"
        let assetGroupName = "Circuit Breaker"
        let assetTypeName = "Three Phase"
        let globalID = UUID(uuidString: "1CAF7740-0BF4-4113-8DB2-654E18800028")!
        
        // Constants for creating the default trace configuration.
        let domainNetworkName = "ElectricDistribution"
        let tierName = "Medium Voltage Radial"
        
        // Load the utility network.
        SVProgressHUD.show(withStatus: "Loading utility network…")
        utilityNetwork.load { [weak self] error in
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Create a default starting location.
                let networkSource = self.utilityNetwork.definition.networkSource(withName: deviceTableName)
                if let assetType = networkSource?.assetGroup(withName: assetGroupName)?.assetType(withName: assetTypeName),
                   let startingLocation = self.utilityNetwork.createElement(with: assetType, globalID: globalID) {
                    // Set the terminal for this location. (For our case, use the "Load" terminal.)
                    startingLocation.terminal = startingLocation.assetType.terminalConfiguration?.terminals.first(where: { $0.name == "Load" })
                    self.startingLocation = startingLocation
                }
                // Get a default trace configuration from a tier to update the UI.
                let domainNetwork = self.utilityNetwork.definition.domainNetwork(withDomainNetworkName: domainNetworkName)
                let utilityTierConfiguration = domainNetwork?.tier(withName: tierName)?.traceConfiguration ?? AGSUtilityTraceConfiguration()
                
                // Set the traversability.
                if utilityTierConfiguration.traversability == nil {
                    utilityTierConfiguration.traversability = AGSUtilityTraversability()
                }
                
                // Set the default expression (if provided).
                if let expression = utilityTierConfiguration.traversability?.barriers as? AGSUtilityTraceConditionalExpression {
                    self.initialExpression = expression
                    if !self.traceConditionalExpressions.contains(expression) {
                        self.traceConditionalExpressions.append(expression)
                    }
                    self.tableView.reloadSections([Section.conditions.rawValue], with: .automatic)
                    // Reload footer label.
                    self.chainedConditionsLabel.text = self.expressionString
                }
                // Set the traversability scope.
                utilityTierConfiguration.traversability?.scope = .junctions
                
                self.configuration = utilityTierConfiguration
            }
        }
    }
    
    /// Chain the conditional expressions together with AND or OR operators.
    ///
    /// - Parameters:
    ///   - chainingOperator: An operator closure which is the initializer
    ///                       of either `AGSUtilityTraceAndCondition` or `AGSUtilityTraceOrCondition`.
    ///   - expressions: An array of `AGSUtilityTraceConditionalExpression`s.
    /// - Returns: The chained conditional expression.
    func chainExpressions(using chainingOperator: (AGSUtilityTraceConditionalExpression, AGSUtilityTraceConditionalExpression) -> AGSUtilityTraceConditionalExpression, expressions: [AGSUtilityTraceConditionalExpression]) -> AGSUtilityTraceConditionalExpression? {
        guard let firstExpression = expressions.first else { return nil }
        return expressions.dropFirst().reduce(firstExpression) { leftCondition, rightCondition in
            chainingOperator(leftCondition, rightCondition)
        }
    }
    
    /// Convert an `AGSUtilityTraceConditionalExpression` into a readable string.
    ///
    /// - Parameter expression: An `AGSUtilityTraceConditionalExpression`.
    /// - Returns: A string describing the expression.
    func expressionToString(expression: AGSUtilityTraceConditionalExpression) -> String {
        switch expression {
        case let categoryComparison as AGSUtilityCategoryComparison:
            let comparisonOperatorString = categoryComparison.comparisonOperator.title
            return "`\(categoryComparison.category.name)` \(comparisonOperatorString)"
        case let attributeComparison as AGSUtilityNetworkAttributeComparison:
            let attributeName = attributeComparison.networkAttribute.name
            let comparisonOperator = attributeComparison.comparisonOperator.title
            if let otherName = attributeComparison.otherNetworkAttribute?.name {
                // Check if it is comparing with another network attribute.
                return "`\(attributeName)` \(comparisonOperator) `\(otherName)`"
            } else if let value = attributeComparison.value {
                let dataType = attributeComparison.networkAttribute.dataType
                if let domain = attributeComparison.networkAttribute.domain as? AGSCodedValueDomain,
                    let codedValue = domain.codedValues.first(where: { compareAttributeData(dataType: dataType, value1: $0.code!, value2: value) }) {
                    // Check if attribute domain is a coded value domain.
                    return "'\(attributeName)' \(comparisonOperator) '\(codedValue.name)'"
                } else {
                    // It is comparing with a user input value.
                    return "`\(attributeName)` \(comparisonOperator) `\(value)`"
                }
            } else {
                fatalError("Unknown attribute comparison expression")
            }
        case let andCondition as AGSUtilityTraceAndCondition:
            return """
            (\(expressionToString(expression: andCondition.leftExpression))) AND
            (\(expressionToString(expression: andCondition.rightExpression)))
            """
        case let orCondition as AGSUtilityTraceOrCondition:
            return """
            (\(expressionToString(expression: orCondition.leftExpression))) OR
            (\(expressionToString(expression: orCondition.rightExpression)))
            """
        default:
            fatalError("Unknown trace condition expression type")
        }
    }
    
    /// Compare two attribute values.
    ///
    /// - Parameters:
    ///   - dataType: An `AGSUtilityNetworkAttributeDataType` enum that tells the type of 2 values.
    ///   - value1: The lhs value to compare.
    ///   - value2: The rhs value to compare.
    /// - Returns: A boolean indicating if the values are euqal both in type and in value.
    func compareAttributeData(dataType: AGSUtilityNetworkAttributeDataType, value1: Any, value2: Any) -> Bool {
        switch dataType {
        case .boolean:
            return value1 as? Bool == value2 as? Bool
        case .double:
            return value1 as? Double == value2 as? Double
        case .float:
            return value1 as? Float == value2 as? Float
        case .integer:
            return value1 as? Int64 == value2 as? Int64
        default:
            return false
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "ConfigureSubnetworkTraceViewController",
            "ConfigureSubnetworkTraceOptionsViewController"
        ]
        loadUtilityNetwork()
        // Assign a custom table footer view.
        tableView.tableFooterView = customFooterView
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController,
            let controller = navigationController.topViewController as? ConfigureSubnetworkTraceOptionsViewController {
            controller.possibleAttributes = utilityNetwork.definition.networkAttributes.filter { !$0.isSystemDefined }
            controller.delegate = self
        }
    }
}

// MARK: - ConfigureSubnetworkTraceOptionsViewControllerDelegate

extension ConfigureSubnetworkTraceViewController: ConfigureSubnetworkTraceOptionsViewControllerDelegate {
    func optionsViewController(_ controller: ConfigureSubnetworkTraceOptionsViewController, didCreate expression: AGSUtilityTraceConditionalExpression) {
        if !traceConditionalExpressions.contains(expression) {
            // Append the new conditional expression if it is not a duplicate.
            traceConditionalExpressions.append(expression)
            // Insert the newly added condition to the table.
            tableView.insertRows(at: [IndexPath(row: traceConditionalExpressions.count - 1, section: Section.conditions.rawValue)], with: .automatic)
            // Reload footer label.
            chainedConditionsLabel.text = expressionString
        }
    }
}

// MARK: - UITableViewDelegate

extension ConfigureSubnetworkTraceViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section.allCases[section].label
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .switches:
            return Switches.allCases.count
        case .conditions:
            return traceConditionalExpressions.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section.allCases[indexPath.section] {
        case .switches:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath)
            switch Switches.allCases[indexPath.row] {
            case .barriers:
                cell.accessoryView = barriersSwitch
                cell.textLabel?.text = Switches.barriers.label
            case .containers:
                cell.accessoryView = containersSwitch
                cell.textLabel?.text = Switches.containers.label
            }
            return cell
        case .conditions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ConditionCell", for: indexPath)
            cell.textLabel?.text = expressionToString(expression: traceConditionalExpressions[indexPath.row])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == Section.conditions.rawValue && indexPath.row != 0 {
            // Enable editing for the rest of conditions section.
            return true
        } else {
            // Disable editing for the first row of conditions section and other rows.
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.section == Section.conditions.rawValue && editingStyle == .delete {
            traceConditionalExpressions.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            // Reload footer label.
            chainedConditionsLabel.text = expressionString
        }
    }
}

private extension AGSUtilityCategoryComparisonOperator {
    /// An extension of `AGSUtilityCategoryComparisonOperator` that returns a human readable description.
    /// - Note: You may also create a `AGSUtilityCategoryComparison` with
    ///         `AGSUtilityNetworkDefinition.categories` and `AGSUtilityCategoryComparisonOperator`.
    var title: String {
        switch self {
        case .exists: return "Exists"
        case .doesNotExist: return "DoesNotExist"
        @unknown default: return "Unknown"
        }
    }
}

private extension AGSUtilityAttributeComparisonOperator {
    /// An extension of `AGSUtilityAttributeComparisonOperator` that returns a human readable description.
    var title: String {
        switch self {
        case .equal: return "Equal"
        case .notEqual: return "NotEqual"
        case .greaterThan: return "GreaterThan"
        case .greaterThanEqual: return "GreaterThanEqual"
        case .lessThan: return "LessThan"
        case .lessThanEqual: return "LessThanEqual"
        case .includesTheValues: return "IncludesTheValues"
        case .doesNotIncludeTheValues: return "DoesNotIncludeTheValues"
        case .includesAny: return "IncludesAny"
        case .doesNotIncludeAny: return "DoesNotIncludeAny"
        @unknown default: return "Unknown"
        }
    }
}
