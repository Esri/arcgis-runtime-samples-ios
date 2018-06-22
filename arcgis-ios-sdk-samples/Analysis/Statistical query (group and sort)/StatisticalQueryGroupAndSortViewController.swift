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

class StatisticalQueryGroupAndSortViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, GroupByFieldsViewControllerDelegate, OrderByFieldsViewControllerDelegate, AddStatisticDefinitionsViewControllerDelegate, UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var getStatisticsButton: UIBarButtonItem!
    @IBOutlet private weak var tableView: UITableView!
    private var serviceFeatureTable: AGSServiceFeatureTable!
    private var fieldNames = [String]()
    private var selectedGroupByFieldNames = [String]()
    private var orderByFields = [AGSOrderBy]()
    private var selectedOrderByFields = [AGSOrderBy]()
    private var statisticDefinitions = [AGSStatisticDefinition]()
    private var sectionHeaderTitles = ["1. Add Statistic Definitions", "2. Select Group By Fields", "3. Select Order By Fields"]
    private var statisticTypes = ["Average", "Count", "Maximum", "Minimum", "StandardDeviation", "Sum", "Variance"]
    private weak var expandableTableViewController: ExpandableTableViewController!
    private weak var groupByFieldsViewController: GroupByFieldsViewController!
    private weak var orderByFieldsViewController: OrderByFieldsViewController!
    private weak var addStatisticDefinitionsViewController: AddStatisticDefinitionsViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["StatisticalQueryGroupAndSortViewController", "AddStatisticDefinitionsViewController", "GroupByFieldsViewController", "OrderByFieldsViewController"]
        
        // Initialize feature table
        serviceFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer/3")!)
        
        // Load feature table
        serviceFeatureTable.load(completion: { [weak self] (error) in
            //
            // If there an error, display it
            guard error == nil else {
                SVProgressHUD.showError(withStatus: error!.localizedDescription)
                return
            }
            
            // Set title
            let tableName = self?.serviceFeatureTable.tableName
            self?.titleLabel.text = "Statistics: \(tableName ?? "")"

            // Get field names
            for field in (self?.serviceFeatureTable.fields)! {
                if field.type != .OID && field.type != .globalID {
                    self?.fieldNames.append(field.name)
                }
            }
        })
        
        // Setup UI Controls
        setupUI()
    }
    
    private func setupUI() {
        //
        // Set corner radius and border for tables
        tableView.layer.cornerRadius = 10
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    // MARK: - Actions
    
    @IBAction private func getStatisticsAction(_ sender: Any) {
        //
        // There should be at least one statistic
        // definition added to execute the query
        if statisticDefinitions.count == 0 || selectedGroupByFieldNames.count == 0 {
            SVProgressHUD.showError(withStatus: "There sould be at least one statistic definition and one group by field to execute the query.")
            return
        }
        
        // Create the parameters with statistic definitions
        let statisticsQueryParameters = AGSStatisticsQueryParameters(statisticDefinitions: statisticDefinitions)

        // Set selected group by fields
        statisticsQueryParameters.groupByFieldNames = selectedGroupByFieldNames
        
        // Set selected order by fields
        statisticsQueryParameters.orderByFields = selectedOrderByFields
        
        // Execute the statistical query with parameters
        serviceFeatureTable?.queryStatistics(with: statisticsQueryParameters, completion: { [weak self] (statisticsQueryResult, error) in
            //
            // If there an error, display it
            guard error == nil else {
                SVProgressHUD.showError(withStatus: error!.localizedDescription)
                return
            }
            
            // Get the result
            if let statisticRecordEnumerator = statisticsQueryResult?.statisticRecordEnumerator() {
                //
                // Setup result view controller
                let storyboard = UIStoryboard(name: "ExpandableTableViewController", bundle: nil)
                self?.expandableTableViewController = storyboard.instantiateViewController(withIdentifier: "ExpandableTableViewController") as! ExpandableTableViewController
                self?.expandableTableViewController.tableTitle = "Statistical Query Results"
                
                // Let's build result message
                while statisticRecordEnumerator.hasNextObject() {
                    let statisticRecord = statisticRecordEnumerator.nextObject()
                    
                    var groups = [String]()
                    for fieldName in (self?.selectedGroupByFieldNames)! {
                        let value = statisticRecord?.group[fieldName] as! String
                        groups.append("\(value)")
                    }
                    self?.expandableTableViewController.sectionHeaderTitles.append(groups.joined(separator: ", "))
                    
                    var statistics = [(String, String)]()
                    for (key, value) in (statisticRecord?.statistics)!  {
                        statistics.append((key, String(describing: value)))
                    }
                    self?.expandableTableViewController.sectionItems.append(statistics)
                }
                
                // Show result
                self?.navigationController?.show((self?.expandableTableViewController)!, sender: self)
            }
        })
    }
    
    @IBAction func resetAction(_ sender: Any) {
        //
        // Reset all collections and reload table
        statisticDefinitions.removeAll()
        selectedGroupByFieldNames.removeAll()
        selectedOrderByFields.removeAll()
        tableView.reloadData()
    }
    
    @objc private func headerButtonAction(_ sender: UIButton) {
        //
        // Check button by tag
        if sender.tag == 0 {
            //
            // Init view controller and set properties
            let storyboard = UIStoryboard(name: "StatisticalQueryGroupAndSort", bundle: nil)
            addStatisticDefinitionsViewController = storyboard.instantiateViewController(withIdentifier: "AddStatisticDefinitionsViewController") as! AddStatisticDefinitionsViewController
            addStatisticDefinitionsViewController.delegate = self
            addStatisticDefinitionsViewController.fieldNames = fieldNames
            addStatisticDefinitionsViewController.statisticDefinitions = statisticDefinitions
            
            // Popover presentation logic
            addStatisticDefinitionsViewController.modalPresentationStyle = .popover
            addStatisticDefinitionsViewController.preferredContentSize = CGSize(width: 350, height: 300)
            addStatisticDefinitionsViewController.presentationController?.delegate = self
            addStatisticDefinitionsViewController.popoverPresentationController?.sourceView = sender
            addStatisticDefinitionsViewController.popoverPresentationController?.sourceRect = sender.bounds
            
            // Present view controller
            self.present(addStatisticDefinitionsViewController, animated: true, completion: nil)
        }
        else if sender.tag == 1 {
            //
            // Init view controller and set properties
            let storyboard = UIStoryboard(name: "StatisticalQueryGroupAndSort", bundle: nil)
            groupByFieldsViewController = storyboard.instantiateViewController(withIdentifier: "GroupByFieldsViewController") as! GroupByFieldsViewController
            groupByFieldsViewController.delegate = self
            groupByFieldsViewController.fieldNames = fieldNames
            groupByFieldsViewController.selectedFieldNames = selectedGroupByFieldNames
            
            // Popover presentation logic
            groupByFieldsViewController.modalPresentationStyle = .popover
            groupByFieldsViewController.preferredContentSize = CGSize(width: 350, height: 300)
            groupByFieldsViewController.presentationController?.delegate = self
            groupByFieldsViewController.popoverPresentationController?.sourceView = sender
            groupByFieldsViewController.popoverPresentationController?.sourceRect = sender.bounds
            
            // Present view controller
            self.present(groupByFieldsViewController, animated: true, completion: nil)
        }
        else if sender.tag == 2 {
            //
            // Init view controller and set properties
            let storyboard = UIStoryboard(name: "StatisticalQueryGroupAndSort", bundle: nil)
            orderByFieldsViewController = storyboard.instantiateViewController(withIdentifier: "OrderByFieldsViewController") as! OrderByFieldsViewController
            orderByFieldsViewController.delegate = self
            orderByFieldsViewController.orderByFields = orderByFields
            orderByFieldsViewController.selectedOrderByFields = selectedOrderByFields
            
            // Popover presentation logic
            orderByFieldsViewController.modalPresentationStyle = .popover
            orderByFieldsViewController.preferredContentSize = CGSize(width: 350, height: 300)
            orderByFieldsViewController.presentationController?.delegate = self
            orderByFieldsViewController.popoverPresentationController?.sourceView = sender
            orderByFieldsViewController.popoverPresentationController?.sourceRect = sender.bounds

            // Present view controller
            self.present(orderByFieldsViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionHeaderTitles.count
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeaderTitles[section]
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        //
        // Create the view
        let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 44))
        returnedView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        returnedView.backgroundColor = .primaryBlue
        returnedView.layer.borderColor = UIColor.white.cgColor
        returnedView.layer.borderWidth = 1

        // Add label
        let label = UILabel(frame: CGRect(x: 10, y: 7, width: view.frame.size.width, height: 25))
        label.text = sectionHeaderTitles[section]
        label.textColor = .white
        returnedView.addSubview(label)

        // Add button
        let headerButton = UIButton(type: .contactAdd)
        headerButton.frame = CGRect(x: tableView.frame.size.width - 32, y: 11, width: 22, height: 22)
        headerButton.tintColor = .white
        headerButton.tag = section
        headerButton.addTarget(self, action:  #selector(headerButtonAction(_:)), for: .touchUpInside)
        returnedView.addSubview(headerButton)
        headerButton.translatesAutoresizingMaskIntoConstraints = false
        returnedView.addConstraint(NSLayoutConstraint(item: headerButton, attribute: .centerY, relatedBy: .equal, toItem: returnedView, attribute: .centerY, multiplier: 1, constant: 0))
        returnedView.addConstraint(NSLayoutConstraint(item: headerButton, attribute: .trailing, relatedBy: .equal, toItem: returnedView, attribute: .trailing, multiplier: 1, constant: -10))

        return returnedView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return statisticDefinitions.count
        }
        else if section == 1 {
            return selectedGroupByFieldNames.count
        }
        else {
            return selectedOrderByFields.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //
        // Build the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath)
        cell.textLabel?.text = ""
        cell.accessoryType = .none
        
        if indexPath.section == 0 {
            if statisticDefinitions.count > 0 {
                let statisticDefinition = statisticDefinitions[indexPath.row]
                let statisticTypeString = statisticTypes[statisticDefinition.statisticType.rawValue]
                let text = "\(statisticDefinition.onFieldName) (\(statisticTypeString))"
                cell.textLabel?.text = text
            }
        }
        else if indexPath.section == 1 {
            if selectedGroupByFieldNames.count > 0 {
                let fieldName = selectedGroupByFieldNames[indexPath.row]
                cell.textLabel?.text = fieldName
            }
        }
        else {
            if selectedOrderByFields.count > 0 {
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if tableView == tableView {
            if (editingStyle == .delete && indexPath.section == 0) {
                if statisticDefinitions.count > 0 {
                    //
                    // Remove statistic definition
                    statisticDefinitions.remove(at: indexPath.row)
                }
            }
            else if (editingStyle == .delete && indexPath.section == 1) {
                //
                // Remove from selected group by field names
                if selectedGroupByFieldNames.count > 0 {
                    //
                    // Get the field name so we can remove order by fields
                    let selectedGroupByFieldName = selectedGroupByFieldNames[indexPath.row]
                    
                    // Remove selected group by field
                    selectedGroupByFieldNames.remove(at: indexPath.row)
                    
                    // Remove field from the order by fields
                    for (i,orderByField) in orderByFields.enumerated().reversed() {
                        if orderByField.fieldName == selectedGroupByFieldName {
                            orderByFields.remove(at: i)
                        }
                    }
                    
                    // Remove field from the selected order by fields
                    for (i,selectedOrderByField) in selectedOrderByFields.enumerated().reversed() {
                        if selectedOrderByField.fieldName == selectedGroupByFieldName {
                            selectedOrderByFields.remove(at: i)
                        }
                    }
                }
            }
            if (editingStyle == .delete && indexPath.section == 2) {
                if selectedOrderByFields.count > 0 {
                    //
                    // Remove selected order by field
                    selectedOrderByFields.remove(at: indexPath.row)
                }
            }
            
            // Reload table
            tableView.reloadData()
        }
    }
    
    // MARK: - Add Statistic Definition View Controller Delegate
    
    func addStatisticDefinitions(_ statisticDefinitions: [AGSStatisticDefinition]) {
        //
        // Set the statistic definitions
        self.statisticDefinitions = statisticDefinitions
        
        // Reload statistic sefinitions section
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }

    // MARK: - Group By Fields View Controller Delegate
    
    func setGrouping(with fieldNames: [String]) {
        //
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
        for (i,orderByField) in selectedOrderByFields.enumerated().reversed() {
            if !orderByFields.contains(where: { $0.fieldName == orderByField.fieldName }) {
                selectedOrderByFields.remove(at: i)
            }
        }
        
        // Reload sections
        tableView.reloadSections(IndexSet([1,2]), with: .automatic)
    }
    
    // MARK: - Order By Fields View Controller Delegate

    func setOrdering(with orderByFields: [AGSOrderBy]) {
        //
        // Set the selected group by fields
        selectedOrderByFields = orderByFields
        
        // Reload order by fields section
        tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        //
        // For popover or non modal presentation
        return UIModalPresentationStyle.none
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return false
    }
    
    // MARK: - Helper Methods
    
    private func stringFor(sortOrder: AGSSortOrder) -> String {
        switch sortOrder {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }
}
