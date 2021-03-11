// Copyright 2021 Esri
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

class CreateLoadReportViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The table view to display the load reports.
    @IBOutlet var tableView: UITableView!
    @IBOutlet var resetBarButtonItem: UIBarButtonItem!
    @IBOutlet var runBarButtonItem: UIBarButtonItem!
    
    // MARK: Properties
    
    /// A feature service for an electric utility network in Naperville, Illinois.
    let utilityNetwork = AGSUtilityNetwork(url: URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!)
    /// The initial conditional expression.
    var initialExpression: AGSUtilityTraceConditionalExpression!
    /// The trace parameters for creating load reports.
    var traceParameters: AGSUtilityTraceParameters!
    /// The network attributes for the comparison.
    var phasesNetworkAttribute: AGSUtilityNetworkAttribute!
    /// A list of possible phases populated from the network's attributes.
    var excludedPhases = [AGSCodedValue]()
    /// A list of phases that are included in the load report.
    var includedPhases = [AGSCodedValue]() {
        didSet {
            let isEmpty = includedPhases.isEmpty
            DispatchQueue.main.async { [weak self] in
                self?.runBarButtonItem.isEnabled = !isEmpty
            }
        }
    }
    /// The phase summaries in the load report.
    var summaries = [AGSCodedValue: PhaseSummary]() {
        didSet {
            if !resetBarButtonItem.isEnabled {
                DispatchQueue.main.async { [weak self] in
                    self?.resetBarButtonItem.isEnabled = true
                }
            }
        }
    }
    
    /// The number formatter for phase summaries.
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        return formatter
    }()
    
    /// A struct for the phase summary, which contains the total customers
    /// and total load for the phase.
    struct PhaseSummary {
        let totalCustomers: Int
        let totalLoad: Int
    }
    
    // MARK: Methods
    
    /// Load the utility network.
    func loadUtilityNetwork() {
        SVProgressHUD.show(withStatus: "Loading utility network…")
        utilityNetwork.load { [weak self] error in
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            guard error == nil else {
                self.presentAlert(error: error!)
                return
            }
            // Create a default starting location.
            guard let startingLocation = self.makeStartingLocation() else {
                self.presentAlert(message: "Fail to create starting location.")
                return
            }
            // Get the base condition and trace configuration from a default tier.
            guard let utilityTierConfiguration = self.getTraceConfiguration() else {
                self.presentAlert(message: "Fail to get trace configuration.")
                return
            }
            // Proceed if the utility network loaded without issue.
            self.utilityNetworkDidLoad(startingLocation: startingLocation, traceConfiguration: utilityTierConfiguration)
        }
    }
    
    /// Called in response to the utility network load operation completing.
    /// - Parameters:
    ///   - startingLocation: The utility element to start the trace from.
    ///   - traceConfiguration: The utility tier's trace configuration.
    func utilityNetworkDidLoad(startingLocation: AGSUtilityElement, traceConfiguration: AGSUtilityTraceConfiguration) {
        // Set the default expression.
        initialExpression = traceConfiguration.traversability?.barriers as? AGSUtilityTraceConditionalExpression
        
        // Create downstream trace parameters with function outputs.
        let traceParameters = AGSUtilityTraceParameters(traceType: .downstream, startingLocations: [startingLocation])
        traceParameters.resultTypes.append(.ags_value(with: .functionOutputs))
        
        // The service category for counting total customers.
        if let serviceCategory = utilityNetwork.definition.categories.first(where: { $0.name == "ServicePoint" }),
           // The load attribute for counting total load.
           let loadAttribute = utilityNetwork.definition.networkAttributes.first(where: { $0.name == "Service Load" }),
           // The phase attribute for getting total phase current load.
           let phasesNetworkAttribute = utilityNetwork.definition.networkAttributes.first(where: { $0.name == "Phases Current" }) {
            self.phasesNetworkAttribute = phasesNetworkAttribute
            // Get possible coded phase values from the attributes.
            if let domain = phasesNetworkAttribute.domain as? AGSCodedValueDomain {
                excludedPhases = domain.codedValues.sorted { $0.name < $1.name }
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.tableView.reloadSections([Section.excluded.rawValue], with: .automatic)
                    self.tableView.isEditing = true
                }
            }
            // Create a comparison to check the existence of service points.
            let serviceCategoryComparison = AGSUtilityCategoryComparison(category: serviceCategory, comparisonOperator: .exists)
            let addLoadAttributeFunction = AGSUtilityTraceFunction(functionType: .add, networkAttribute: loadAttribute, condition: serviceCategoryComparison)
            // Create function input and output condition.
            traceConfiguration.functions = [addLoadAttributeFunction]
            traceConfiguration.outputCondition = serviceCategoryComparison
            // Assign the trace configuration to trace parameters.
            traceParameters.traceConfiguration = traceConfiguration
            self.traceParameters = traceParameters
        }
    }
    
    /// When the utility network is loaded, create an `AGSUtilityElement`
    /// from the asset type to use as the starting location for the trace.
    func makeStartingLocation() -> AGSUtilityElement? {
        // Constants for creating the default starting location.
        let deviceTableName = "Electric Distribution Device"
        let assetGroupName = "Circuit Breaker"
        let assetTypeName = "Three Phase"
        let terminalName = "Load"
        let globalID = UUID(uuidString: "1CAF7740-0BF4-4113-8DB2-654E18800028")!
        
        // Create a default starting location.
        if let networkSource = utilityNetwork.definition.networkSource(withName: deviceTableName),
           let assetType = networkSource.assetGroup(withName: assetGroupName)?.assetType(withName: assetTypeName),
           let startingLocation = utilityNetwork.createElement(with: assetType, globalID: globalID) {
            // Set the terminal for the location. (For our case, use the "Load" terminal.)
            startingLocation.terminal = assetType.terminalConfiguration?.terminals.first(where: { $0.name == terminalName })
            return startingLocation
        } else {
            return nil
        }
    }
    
    /// Get the utility tier's trace configuration.
    func getTraceConfiguration() -> AGSUtilityTraceConfiguration? {
        // Get a default trace configuration from a tier in the network.
        utilityNetwork
            .definition
            .domainNetwork(withDomainNetworkName: "ElectricDistribution")?
            .tier(withName: "Medium Voltage Radial")?
            .traceConfiguration
    }
    
    // MARK: Actions
    
    @IBAction func resetBarButtonItemTapped(_ sender: UIBarButtonItem) {
        summaries.removeAll()
        tableView.reloadSections([Section.included.rawValue], with: .automatic)
        resetBarButtonItem.isEnabled = false
        runBarButtonItem.isEnabled = !includedPhases.isEmpty
    }
    
    @IBAction func runBarButtonItemTapped(_ sender: UIBarButtonItem) {
        runBarButtonItem.isEnabled = false
        SVProgressHUD.show(withStatus: "Creating load report…")
        
        let traceGroup = DispatchGroup()
        for phase in includedPhases {
            guard let phaseCode = phase.code else { continue }
            // Create a conditional expression.
            let phasesAttributeComparison = AGSUtilityNetworkAttributeComparison(networkAttribute: phasesNetworkAttribute, comparisonOperator: .doesNotIncludeAny, value: phaseCode)!
            // Chain it with the base condition using an OR operator.
            traceParameters.traceConfiguration?.traversability?.barriers = AGSUtilityTraceOrCondition(leftExpression: initialExpression, rightExpression: phasesAttributeComparison)
            
            traceGroup.enter()
            utilityNetwork.trace(with: traceParameters) { [weak self] results, _ in
                defer { traceGroup.leave() }
                // Return if not result and ignore any trace error.
                guard let self = self, let results = results else { return }
                var totalCustomers = 0
                var totalLoad = 0
                results.forEach { result in
                    switch result {
                    case let elementResult as AGSUtilityElementTraceResult:
                        // Get the unique customers count.
                        totalCustomers = Set(elementResult.elements.map(\.objectID)).count
                    case let functionResult as AGSUtilityFunctionTraceResult:
                        // Get the total load with a function output.
                        totalLoad = functionResult.functionOutputs.first?.result as? Int ?? 0
                    default:
                        break
                    }
                }
                self.summaries[phase] = PhaseSummary(totalCustomers: totalCustomers, totalLoad: totalLoad)
            }
        }
        // Reload the load report table when trace completes.
        traceGroup.notify(queue: .main) { [weak self] in
            SVProgressHUD.dismiss()
            self?.tableView.reloadSections([Section.included.rawValue], with: .automatic)
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["CreateLoadReportViewController"]
        // Load the utility network and initialize properties.
        loadUtilityNetwork()
    }
}

// MARK: - UITableViewDelegate

extension CreateLoadReportViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section.allCases[section].titleForHeader
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .included:
            return includedPhases.count
        case .excluded:
            return excludedPhases.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        let phase: AGSCodedValue
        switch Section.allCases[indexPath.section] {
        case .included:
            cell = tableView.dequeueReusableCell(withIdentifier: Section.included.cellIdentifier, for: indexPath)
            phase = includedPhases[indexPath.row]
            cell.textLabel?.text = "Phase: " + phase.name
            if let summary = summaries[phase] {
                cell.detailTextLabel?.text = "C: " + numberFormatter.string(from: NSNumber(value: summary.totalCustomers))! + "    L: " + numberFormatter.string(from: NSNumber(value: summary.totalLoad))!
            } else {
                cell.detailTextLabel?.text = "N/A"
            }
        case .excluded:
            cell = tableView.dequeueReusableCell(withIdentifier: Section.excluded.cellIdentifier, for: indexPath)
            phase = excludedPhases[indexPath.row]
            cell.textLabel?.text = phase.name
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        switch Section.allCases[indexPath.section] {
        case .included:
            return .delete
        case .excluded:
            return .insert
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        tableView.beginUpdates()
        switch editingStyle {
        case .delete:
            tableView.deleteRows(at: [indexPath], with: .automatic)
            let phase = includedPhases[indexPath.row]
            includedPhases.remove(at: indexPath.row)
            // Binary search to find the insertion index.
            let insertionIndex = (excludedPhases as NSArray).index(
                of: phase,
                inSortedRange: NSRange(excludedPhases.indices),
                options: [.insertionIndex],
                usingComparator: { ($0 as! AGSCodedValue).name.compare(($1 as! AGSCodedValue).name) }
            )
            excludedPhases.insert(phase, at: insertionIndex)
            let section = Section.excluded.rawValue
            tableView.insertRows(at: [IndexPath(row: insertionIndex, section: section)], with: .automatic)
        case .insert:
            tableView.deleteRows(at: [indexPath], with: .automatic)
            let phase = excludedPhases[indexPath.row]
            excludedPhases.remove(at: indexPath.row)
            includedPhases.append(phase)
            let section = Section.included.rawValue
            let newRow = tableView.numberOfRows(inSection: section)
            tableView.insertRows(at: [IndexPath(row: newRow, section: section)], with: .automatic)
        default:
            break
        }
        tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let phase = includedPhases[sourceIndexPath.row]
        includedPhases.remove(at: sourceIndexPath.row)
        includedPhases.insert(phase, at: destinationIndexPath.row)
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Only allow moving rows in the included phases section.
        Section.allCases[indexPath.section] == .included
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        // Only allow moving rows in the included phases section.
        sourceIndexPath.section != proposedDestinationIndexPath.section ? sourceIndexPath : proposedDestinationIndexPath
    }
}

// MARK: Section Enum

extension CreateLoadReportViewController {
    /// A convenience type for the table view sections.
    enum Section: Int, CaseIterable {
        case included, excluded
        
        var titleForHeader: String {
            switch self {
            case .included:
                return "Phases, Total Customers(C), Total Load(L)"
            case .excluded:
                return "More Phases"
            }
        }
        
        var cellIdentifier: String {
            switch self {
            case .included:
                return "RightDetail"
            case .excluded:
                return "Basic"
            }
        }
    }
}
