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
    
    // MARK: Properties
    
    /// A feature service for an electric utility network in Naperville, Illinois.
    let utilityNetwork = AGSUtilityNetwork(url: URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!)
    /// The utility element to start the trace from.
    var startingLocation: AGSUtilityElement?
    /// The initial conditional expression.
    var initialExpression: AGSUtilityTraceConditionalExpression?
    /// The trace parameters for creating load reports.
    var traceParameters: AGSUtilityTraceParameters?
    /// The network attributes for the comparison.
    var phasesNetworkAttribute: AGSUtilityNetworkAttribute?
    /// A list of possible phases populated from the network's attributes.
    var phaseChoices = [AGSCodedValue]()
    /// A list of phases for which to create load reports.
    var phaseSummaries = [(phase: AGSCodedValue, summary: PhaseSummary?)]()
    
    /// A struct for the phase summary, which contains the phase,
    /// the total customers and total load for the phase.
    struct PhaseSummary {
        let phase: AGSCodedValue
        let totalCustomers: Int
        let totalLoad: Int
        
        var description: String {
            "Customers: \(totalCustomers)\tLoad: \(totalLoad)"
        }
    }
    
    // MARK: Methods
    
    func loadUtilityNetwork() {
        // For counting total customers.
        let serviceCategoryName = "ServicePoint"
        // For counting total load.
        let loadNetworkAttributeName = "Service Load"
        // Get load report for phases.
        let phasesNetworkAttributeName = "Phases Current"
        
        // Load the utility network.
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
            // Set the starting location.
            self.startingLocation = startingLocation
            // Set the default expression.
            self.initialExpression = utilityTierConfiguration.traversability?.barriers as? AGSUtilityTraceConditionalExpression
            
            // Create downstream trace parameters with function outputs.
            self.traceParameters = AGSUtilityTraceParameters(traceType: .downstream, startingLocations: [startingLocation])
            self.traceParameters?.resultTypes.append(.ags_value(with: .functionOutputs))
            // Create function input and output condition.
            if let serviceCategory = self.utilityNetwork.definition.categories.first(where: { $0.name == serviceCategoryName }),
               let loadAttribute = self.utilityNetwork.definition.networkAttributes.first(where: { $0.name == loadNetworkAttributeName }),
               let phasesNetworkAttribute = self.utilityNetwork.definition.networkAttributes.first(where: { $0.name == phasesNetworkAttributeName }) {
                self.phasesNetworkAttribute = phasesNetworkAttribute
                // Get possible coded phase values from the attributes.
                if let domain = phasesNetworkAttribute.domain as? AGSCodedValueDomain {
                    self.phaseChoices = domain.codedValues.sorted { $0.name < $1.name }
                    self.addDefaultPhase()
                }
                // Create a comparison to check the existence of service points.
                let serviceCategoryComparison = AGSUtilityCategoryComparison(category: serviceCategory, comparisonOperator: .exists)
                let addLoadAttributeFunction = AGSUtilityTraceFunction(functionType: .add, networkAttribute: loadAttribute, condition: serviceCategoryComparison)
                utilityTierConfiguration.functions = [addLoadAttributeFunction]
                utilityTierConfiguration.outputCondition = serviceCategoryComparison
                // Assign the trace configuration to trace parameters.
                self.traceParameters?.traceConfiguration = utilityTierConfiguration
            }
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
        let networkSource = utilityNetwork.definition.networkSource(withName: deviceTableName)
        if let assetType = networkSource?.assetGroup(withName: assetGroupName)?.assetType(withName: assetTypeName),
           let startingLocation = utilityNetwork.createElement(with: assetType, globalID: globalID),
           let terminal = assetType.terminalConfiguration?.terminals.first(where: { $0.name == terminalName }) {
            // Set the terminal for the location. (For our case, use the "Load" terminal.)
            startingLocation.terminal = terminal
            return startingLocation
        }
        return nil
    }
    
    /// Get the utility tier's trace configuration.
    func getTraceConfiguration() -> AGSUtilityTraceConfiguration? {
        // Constants for creating the default trace configuration.
        let domainNetworkName = "ElectricDistribution"
        let tierName = "Medium Voltage Radial"
        // Get a default trace configuration from a tier to update the UI.
        let domainNetwork = utilityNetwork.definition.domainNetwork(withDomainNetworkName: domainNetworkName)
        let utilityTierConfiguration = domainNetwork?.tier(withName: tierName)?.traceConfiguration
        return utilityTierConfiguration
    }
    
    /// Add a default phase to the list to better showcase the sample.
    func addDefaultPhase() {
        guard let defaultPhase = phaseChoices.first else { return }
        phaseSummaries.append((defaultPhase, nil))
        tableView.insertRows(at: [IndexPath(row: phaseSummaries.endIndex - 1, section: 0)], with: .automatic)
    }
    
    // MARK: Actions
    
    @IBAction func resetBarButtonItemTapped(_ sender: UIBarButtonItem) {
        phaseSummaries.removeAll()
        tableView.reloadData()
    }
    
    @IBAction func addBarButtonItemTapped(_ sender: UIBarButtonItem) {
        let selectedPhases = Set(phaseSummaries.map { $0.phase })
        let remainingPhases = phaseChoices.filter { !selectedPhases.contains($0) }
        guard !remainingPhases.isEmpty else { return }
        let alertController = UIAlertController(
            title: "Add a phase to get the load report.",
            message: nil,
            preferredStyle: .actionSheet
        )
        remainingPhases.forEach { phase in
            alertController.addAction(UIAlertAction(title: phase.name, style: .default) { _ in
                self.phaseSummaries.append((phase, nil))
                self.tableView.insertRows(at: [IndexPath(row: self.phaseSummaries.endIndex - 1, section: 0)], with: .automatic)
            })
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = sender
        present(alertController, animated: true)
    }
    
    @IBAction func runBarButtonItemTapped(_ sender: UIBarButtonItem) {
        guard !phaseSummaries.isEmpty,
              let expression = initialExpression,
              let phasesNetworkAttribute = phasesNetworkAttribute,
              let traceParameters = traceParameters else { return }
        
        let traceGroup = DispatchGroup()
        SVProgressHUD.show(withStatus: "Creating load report…")
        
        for i in 0..<phaseSummaries.count {
            let phase = phaseSummaries[i].phase
            guard let phaseCode = phase.code else { continue }
            // Create a conditional expression.
            let phasesAttributeComparison = AGSUtilityNetworkAttributeComparison(networkAttribute: phasesNetworkAttribute, comparisonOperator: .doesNotIncludeAny, value: phaseCode)!
            // Chain it with the base condition using an OR operator.
            traceParameters.traceConfiguration?.traversability?.barriers = AGSUtilityTraceOrCondition(leftExpression: expression, rightExpression: phasesAttributeComparison)
            
            traceGroup.enter()
            utilityNetwork.trace(with: traceParameters) { [weak self] results, _ in
                defer {
                    traceGroup.leave()
                }
                // Return if not result and ignore any trace error.
                guard let results = results else { return }
                var totalCustomers = 0
                var totalLoad = 0
                results.forEach { result in
                    if let elementResult = result as? AGSUtilityElementTraceResult {
                        // Get the unique customers count.
                        totalCustomers = Set(elementResult.elements.map { $0.objectID }).count
                    } else if let functionResult = result as? AGSUtilityFunctionTraceResult {
                        // Get the total load with a function output.
                        totalLoad = functionResult.functionOutputs.first?.result as? Int ?? 0
                    }
                }
                self?.phaseSummaries[i].summary = PhaseSummary(phase: phase, totalCustomers: totalCustomers, totalLoad: totalLoad)
            }
        }
        // Reload the load report table when trace completes.
        traceGroup.notify(queue: .main) { [weak self] in
            SVProgressHUD.dismiss()
            self?.tableView.reloadData()
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
        "Phases, Total Customers, Total Load"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "Tap the add button to add phases.\nTap \"Run\" to get load reports."
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        phaseSummaries.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RightDetail", for: indexPath)
        let (phase, summary) = phaseSummaries[indexPath.row]
        cell.textLabel?.text = "Phase: \(phase.name)"
        cell.detailTextLabel?.text = (summary?.description) ?? "Customers: N/A\tLoad: N/A"
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            phaseSummaries.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
