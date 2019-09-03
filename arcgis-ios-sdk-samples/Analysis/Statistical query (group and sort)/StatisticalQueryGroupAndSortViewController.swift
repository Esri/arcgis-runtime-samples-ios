//
// Copyright 2018 Esri.
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

class StatisticalQueryGroupAndSortViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GroupByFieldsViewControllerDelegate, OrderByFieldsViewControllerDelegate, AddStatisticDefinitionsViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var getStatisticsButton: UIBarButtonItem!
    @IBOutlet private weak var tableView: UITableView!
    
    private var serviceFeatureTable: AGSServiceFeatureTable?
    private var fieldNames = [String]()
    private var numericFieldNames = [String]()
    private var selectedGroupByFieldNames = [String]()
    private var orderByFields = [AGSOrderBy]()
    private var selectedOrderByFields = [AGSOrderBy]()
    private var statisticDefinitions = [AGSStatisticDefinition]()
    private var statisticTypes = ["Average", "Count", "Maximum", "Minimum", "StandardDeviation", "Sum", "Variance"]
    private var statisticsQueryResult: AGSStatisticsQueryResult?
    
    private enum Section: CaseIterable {
        case definitions, groupByFields, orderByFields
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["StatisticalQueryGroupAndSortViewController", "AddStatisticDefinitionsViewController", "GroupByFieldsViewController", "OrderByFieldsViewController", "OptionsTableViewController"]
        
        let serviceURL = URL(string: "https://services.arcgis.com/jIL9msH9OI208GCb/arcgis/rest/services/Counties_Obesity_Inactivity_Diabetes_2013/FeatureServer/0")!
        
        // Initialize feature table
        let serviceFeatureTable = AGSServiceFeatureTable(url: serviceURL)
        self.serviceFeatureTable = serviceFeatureTable
        
        // Load feature table
        serviceFeatureTable.load { [weak self] (error) in
            guard let self = self else {
                return
            }
            
            // If there an error, display it
            guard error == nil else {
                self.presentAlert(error: error!)
                return
            }
            
            // Set title
            let tableName = serviceFeatureTable.tableName
            self.titleLabel.text = "Statistics: \(tableName)"
            
            // Get field names
            self.fieldNames = serviceFeatureTable.fields.compactMap { (field) -> String? in
                if field.type != .OID && field.type != .globalID {
                    return field.name
                }
                return nil
            }
            self.numericFieldNames = serviceFeatureTable.fields.compactMap { (field) -> String? in
                if field.type == .double ||
                    field.type == .float ||
                    field.type == .int32 ||
                    field.type == .int16 {
                    return field.name
                }
                return nil
            }
        }
        
        // Setup UI Controls
        setupUI()
    }
    
    private func setupUI() {
        // Set corner radius and border for tables
        tableView.layer.cornerRadius = 10
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    // MARK: - Actions
    
    @IBAction private func getStatisticsAction(_ sender: Any) {
        // There should be at least one statistic
        // definition added to execute the query
        guard !statisticDefinitions.isEmpty,
            !selectedGroupByFieldNames.isEmpty else {
            presentAlert(message: "There should be at least one statistic definition and one group by field to execute the query.")
            return
        }
        
        // Create the parameters with statistic definitions
        let statisticsQueryParameters = AGSStatisticsQueryParameters(statisticDefinitions: statisticDefinitions)

        // Set selected group by fields
        statisticsQueryParameters.groupByFieldNames = selectedGroupByFieldNames
        
        // Set selected order by fields
        statisticsQueryParameters.orderByFields = selectedOrderByFields
        
        // Execute the statistical query with parameters
        serviceFeatureTable?.queryStatistics(with: statisticsQueryParameters) { [weak self] (statisticsQueryResult, error) in
            guard let self = self else {
                return
            }
            
            // If there an error, display it
            if let error = error {
                self.presentAlert(error: error)
            } else if let statisticsQueryResult = statisticsQueryResult {
                // Setup result view controller
                self.statisticsQueryResult = statisticsQueryResult
                self.performSegue(withIdentifier: "ShowResultsSegue", sender: self)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? GroupSortQueryResultsViewController {
            controller.selectedGroupByFieldNames = selectedGroupByFieldNames
            controller.statisticsQueryResult = statisticsQueryResult
        }
    }
    
    @IBAction func resetAction(_ sender: Any) {
        // Reset all collections and reload table
        statisticDefinitions.removeAll()
        selectedGroupByFieldNames.removeAll()
        selectedOrderByFields.removeAll()
        tableView.reloadData()
    }
    
    @objc
    private func headerButtonAction(_ sender: UIButton) {
        func setupAndPresent(viewController: UIViewController) {
            // Popover presentation logic
            viewController.modalPresentationStyle = .popover
            viewController.preferredContentSize = CGSize(width: 350, height: 300)
            viewController.presentationController?.delegate = self
            viewController.popoverPresentationController?.sourceView = sender
            viewController.popoverPresentationController?.sourceRect = sender.bounds
            
            // Present view controller
            present(viewController, animated: true)
        }

        // Check button by tag
        switch Section.allCases[sender.tag] {
        case .definitions:
            // Init view controller and set properties
            let navController = storyboard!.instantiateViewController(withIdentifier: "AddStatisticDefinitionsViewController") as! UINavigationController
            let addStatisticDefinitionsViewController = navController.viewControllers.first as! AddStatisticDefinitionsViewController
            addStatisticDefinitionsViewController.delegate = self
            addStatisticDefinitionsViewController.fieldNames = numericFieldNames
            setupAndPresent(viewController: navController)
        case .groupByFields:
            // Init view controller and set properties
            let groupByFieldsViewController = storyboard!.instantiateViewController(withIdentifier: "GroupByFieldsViewController") as! GroupByFieldsViewController
            groupByFieldsViewController.delegate = self
            groupByFieldsViewController.fieldNames = fieldNames
            groupByFieldsViewController.selectedFieldNames = selectedGroupByFieldNames
            setupAndPresent(viewController: groupByFieldsViewController)
        case .orderByFields:
            // Init view controller and set properties
            let orderByFieldsViewController = storyboard!.instantiateViewController(withIdentifier: "OrderByFieldsViewController") as! OrderByFieldsViewController
            orderByFieldsViewController.delegate = self
            orderByFieldsViewController.orderByFields = orderByFields
            orderByFieldsViewController.selectedOrderByFields = selectedOrderByFields
            setupAndPresent(viewController: orderByFieldsViewController)
        }
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Create the view
        let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 44))
        returnedView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        returnedView.backgroundColor = .primaryBlue
        returnedView.layer.borderColor = UIColor.white.cgColor
        returnedView.layer.borderWidth = 1

        // Add label
        let label = UILabel(frame: CGRect(x: 10, y: 7, width: view.frame.size.width, height: 25))
        label.text = {
            switch Section.allCases[section] {
            case .definitions:
                return  "1. Add Statistic Definitions"
            case .groupByFields:
                return "2. Select Group By Fields"
            case .orderByFields:
                return "3. Select Order By Fields"
            }
        }()
        label.textColor = .white
        returnedView.addSubview(label)

        // Add button
        let headerButton = UIButton(type: .contactAdd)
        headerButton.frame = CGRect(x: tableView.frame.size.width - 32, y: 11, width: 22, height: 22)
        headerButton.tintColor = .white
        headerButton.tag = section
        headerButton.addTarget(self, action: #selector(headerButtonAction(_:)), for: .touchUpInside)
        returnedView.addSubview(headerButton)
        headerButton.translatesAutoresizingMaskIntoConstraints = false
        returnedView.addConstraint(NSLayoutConstraint(item: headerButton, attribute: .centerY, relatedBy: .equal, toItem: returnedView, attribute: .centerY, multiplier: 1, constant: 0))
        returnedView.addConstraint(NSLayoutConstraint(item: headerButton, attribute: .trailing, relatedBy: .equal, toItem: returnedView, attribute: .trailing, multiplier: 1, constant: -10))

        return returnedView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section.allCases[section] {
        case .definitions:
            return statisticDefinitions.count
        case .groupByFields:
            return selectedGroupByFieldNames.count
        case .orderByFields:
            return selectedOrderByFields.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Build the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        cell.textLabel?.text = ""
        cell.accessoryType = .none
        
        switch Section.allCases[indexPath.section] {
        case .definitions:
            if !statisticDefinitions.isEmpty {
                let statisticDefinition = statisticDefinitions[indexPath.row]
                let statisticTypeString = statisticTypes[statisticDefinition.statisticType.rawValue]
                let text = "\(statisticDefinition.onFieldName) (\(statisticTypeString))"
                cell.textLabel?.text = text
            }
        case .groupByFields:
            if !selectedGroupByFieldNames.isEmpty {
                let fieldName = selectedGroupByFieldNames[indexPath.row]
                cell.textLabel?.text = fieldName
            }
        case .orderByFields:
            if !selectedOrderByFields.isEmpty {
                let orderByField = selectedOrderByFields[indexPath.row]
                let sortOrderString = stringFor(sortOrder: orderByField.sortOrder)
                let text = "\(orderByField.fieldName) (\(sortOrderString))"
                cell.textLabel?.text = text
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // only deletion is allowed
        guard editingStyle == .delete else {
            return
        }
        switch Section.allCases[indexPath.section] {
        case .definitions:
            // Remove statistic definition
            statisticDefinitions.remove(at: indexPath.row)
        case .groupByFields:
            // Remove selected group by field
            let selectedGroupByFieldName = selectedGroupByFieldNames.remove(at: indexPath.row)
            
            // Remove field from the order by fields
            orderByFields.removeAll { $0.fieldName == selectedGroupByFieldName }
            
            // Remove field from the selected order by fields
            selectedOrderByFields.removeAll { $0.fieldName == selectedGroupByFieldName }
        case .orderByFields:
            // Remove selected order by field
            selectedOrderByFields.remove(at: indexPath.row)
        }
        
        // Reload table
        tableView.reloadData()
    }
    
    // MARK: - Add Statistic Definition View Controller Delegate
    
    func addStatisticDefinition(_ statisticDefinition: AGSStatisticDefinition) {
        // Set the statistic definitions
        statisticDefinitions.append(statisticDefinition)
        
        // Reload statistic sefinitions section
        tableView.reloadSections([0], with: .automatic)
    }

    // MARK: - Group By Fields View Controller Delegate
    
    func setGrouping(with fieldNames: [String]) {
        // Set the selected group by fields
        selectedGroupByFieldNames = fieldNames
        
        // Remove all order by fields
        orderByFields.removeAll()
        
        // Add field name to the order by fields
        for fieldName in selectedGroupByFieldNames {
            let orderBy = AGSOrderBy(fieldName: fieldName, sortOrder: .ascending)
            orderByFields.append(orderBy)
        }
        
        // Remove selected order by field if it's not part of the new order by fields
        selectedOrderByFields.removeAll { (orderBy) -> Bool in
            !orderByFields.contains { $0.fieldName == orderBy.fieldName }
        }
        
        // Reload sections
        tableView.reloadSections(IndexSet([1, 2]), with: .automatic)
    }
    
    // MARK: - Order By Fields View Controller Delegate

    func setOrdering(with orderByFields: [AGSOrderBy]) {
        // Set the selected group by fields
        selectedOrderByFields = orderByFields
        
        // Reload order by fields section
        tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // For popover or non modal presentation
        return .none
    }
    
    // MARK: - Helper Methods
    
    private func stringFor(sortOrder: AGSSortOrder) -> String {
        switch sortOrder {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        @unknown default:
            return "Unknown"
        }
    }
}

class GroupSortQueryResultsViewController: UITableViewController {
    var statisticsQueryResult: AGSStatisticsQueryResult? {
        didSet {
            statisticRecords = statisticsQueryResult?.statisticRecordEnumerator().allObjects ?? []
        }
    }
    
    var selectedGroupByFieldNames: [String] = []
    
    var statisticRecords: [AGSStatisticRecord] = [] {
        didSet {
            guard isViewLoaded else {
                return
            }
            tableView?.reloadData()
        }
    }
    
    @IBAction func closeButtonAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? GroupSortQueryResultsDetailViewController,
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell) {
            controller.title = cell.textLabel?.text
            controller.statisticRecord = statisticRecords[indexPath.row]
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statisticRecords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordCell", for: indexPath)
        let record = statisticRecords[indexPath.row]
        let groupNames = selectedGroupByFieldNames.compactMap { record.group[$0] as? String }
        cell.textLabel?.text = groupNames.joined(separator: ", ")
        return cell
    }
}

class GroupSortQueryResultsDetailViewController: UITableViewController {
    var statisticRecord: AGSStatisticRecord? {
        didSet {
            statistics = statisticRecord?.statistics.sorted { $0.key < $1.key } ?? []
        }
    }
    
    var statistics: [(key: String, value: Any)] = [] {
        didSet {
            guard isViewLoaded else {
                return
            }
            tableView?.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statistics.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StatisticCell", for: indexPath)
        let statistic = statistics[indexPath.row]
        cell.textLabel?.text = statistic.key
        cell.detailTextLabel?.text = String(describing: statistic.value)
        return cell
    }
}
