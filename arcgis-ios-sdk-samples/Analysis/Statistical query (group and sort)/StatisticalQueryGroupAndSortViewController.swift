//
// Copyright 2017 Esri.
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

class StatisticalQueryGroupAndSortViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet private weak var fieldNamePicker: HorizontalPicker!
    @IBOutlet private weak var statisticTypePicker: HorizontalPicker!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var getStatisticsButton: UIBarButtonItem!
    @IBOutlet private weak var tableView: UITableView!
    private var serviceFeatureTable: AGSServiceFeatureTable!
    private var fieldNames = [String]()
    private var selectedGroupByFieldNames = [String]()
    private var orderByFields = [AGSOrderBy]()
    private var selectedOrderByFields = [AGSOrderBy]()
    private var statisticDefinitions = [AGSStatisticDefinition]()
    private var statisticTypes = ["Average", "Count", "Maximum", "Minimum", "StandardDeviation", "Sum", "Variance"]
    private var sectionHeaderTitles = ["Statistic Definitions", "Group By Fields", "Order By Fields"];
    private weak var expandableTableViewController: ExpandableTableViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["StatisticalQueryGroupAndSortViewController"]
        
        // Initialize feature table
        serviceFeatureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Census/MapServer/3")!)
        
        // Load feature table
        serviceFeatureTable.load(completion: { [weak self] (error) in
            //
            // If there an error, display it
            guard error == nil else {
                SVProgressHUD.show(withStatus: error!.localizedDescription, maskType: .gradient)
                return
            }
            
            // Set title
            let tableName = self?.serviceFeatureTable.tableName
            self?.titleLabel.text = "Statistics: \(tableName ?? "")"

            // Get field names
            for field in (self?.serviceFeatureTable.fields)! {
                self?.fieldNames.append(field.name)
            }
            self?.fieldNamePicker.options = self?.fieldNames
            self?.tableView.reloadData()
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
        
        // Set corner radius for title label
        titleLabel.layer.cornerRadius = 8
        titleLabel.clipsToBounds = true
        
        // Add picker options
        fieldNamePicker.options = fieldNames
        statisticTypePicker.options =  statisticTypes
        
        // Register table cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    // MARK: - Actions
    
    @IBAction func addStatisticDefinitionAction(_ sender: Any) {
        //
        // Add statistic definition
        let fieldName = fieldNamePicker.options[fieldNamePicker.selectedIndex]
        let statisticType = AGSStatisticType(rawValue: statisticTypePicker.selectedIndex)
        let statisticDefinition = AGSStatisticDefinition(onFieldName: fieldName, statisticType: statisticType!, outputAlias: nil)
        statisticDefinitions.append(statisticDefinition)
        
        // Reload section
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    @IBAction private func getStatisticsAction(_ sender: Any) {
        //
        // There should be at least one statistic
        // definition added to execute the query
        if statisticDefinitions.count == 0 || selectedGroupByFieldNames.count == 0 {
            SVProgressHUD.showError(withStatus: "There sould be at least one statistic definition and one group by field to execute the query.", maskType: .gradient)
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
                SVProgressHUD.show(withStatus: error!.localizedDescription, maskType: .gradient)
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
                    print(statisticRecord?.group as Any)
                    
                    var groups = [String]()
                    for (key, value) in (statisticRecord?.group)!  {
                        groups.append("\(key):\(value)")
                    }
                    self?.expandableTableViewController.sectionHeaderTitles.append(groups.joined(separator: ", "))
                    
                    var statistics = [(String, String)]()
                    for (key, value) in (statisticRecord?.statistics)!  {
                        print("\(key): \(value)")
                        statistics.append((key, String(describing: value)))
                    }
                    self?.expandableTableViewController.sectionItems.append(statistics)
                }

                // Only for iPad, set presentation style to Form sheet
                // We don't want it to cover the entire screen
                self?.expandableTableViewController.modalPresentationStyle = .formSheet
                
                // Show result
                self?.present((self?.expandableTableViewController)!, animated: true, completion: nil)
            }
        })
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
        let returnedView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44))
        returnedView.backgroundColor = UIColor.primaryBlue()
        returnedView.layer.borderColor = UIColor.white.cgColor
        returnedView.layer.borderWidth = 1

        let label = UILabel(frame: CGRect(x: 10, y: 7, width: view.frame.size.width, height: 25))
        label.text = sectionHeaderTitles[section]
        label.textColor = UIColor.white
        returnedView.addSubview(label)
        return returnedView
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return statisticDefinitions.count
        }
        else if section == 1 {
            return fieldNames.count
        }
        else {
            return orderByFields.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //
        // Build the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
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
            if fieldNames.count > 0 {
                let fieldName = fieldNames[indexPath.row]
                cell.textLabel?.text = fieldName
                
                if selectedGroupByFieldNames.contains(fieldName) {
                    cell.accessoryType = .checkmark
                }
            }
        }
        else {
            if orderByFields.count > 0 {
                let orderByField = orderByFields[indexPath.row]
                cell.textLabel?.text = orderByField.fieldName
                
                if selectedOrderByFields.contains(orderByField) {
                    cell.accessoryType = .checkmark
                }
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 0 {
            return true
        }
        else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if tableView == tableView {
            if (editingStyle == .delete) {
                if statisticDefinitions.count > 0 {
                    statisticDefinitions.remove(at: indexPath.row)
                    tableView.reloadData()
                }
            }
        }
    }
    
    //MARK: - Table View Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
        // Deselect row
        tableView.deselectRow(at: indexPath, animated: false)
        
        // For Group By Fields section
        // set the accessory type and
        // build Order By Fields array
        if indexPath.section == 1 {
            //
            // Get the cell
            if let cell = tableView.cellForRow(at: indexPath) {
                if cell.accessoryType == .none {
                    //
                    // Set the accessory type to checkmark
                    cell.accessoryType = .checkmark
                    
                    // Add field name to selected group by fields
                    selectedGroupByFieldNames.append((cell.textLabel?.text)!)
                    
                    // Add field name to the order by fields
                    //orderByFieldNames.append((cell.textLabel?.text)!)
                    let orderBy = AGSOrderBy(fieldName: (cell.textLabel?.text)!, sortOrder: .ascending)
                    orderByFields.append(orderBy)
                }
                else {
                    //
                    // Set the accessory type to none
                    cell.accessoryType = .none
                    
                    // Remove field name from the selected group by fields
                    let index = selectedGroupByFieldNames.index(of: (cell.textLabel?.text)!)
                    selectedGroupByFieldNames.remove(at: index!)
                    
                    // Remove field from the order by fields
                    for i in 0 ..< orderByFields.count {
                        let orderByField = orderByFields[i]
                        if orderByField.fieldName == (cell.textLabel?.text)! {
                            orderByFields.remove(at: i)
                            break
                        }
                    }
                }
            }
        }
        else if indexPath.section == 2 {
            //
            // Get the cell
            if let cell = tableView.cellForRow(at: indexPath) {
                if cell.accessoryType == .none {
                    //
                    // Set the accessory type to checkmark
                    cell.accessoryType = .checkmark
                    
                    // Add field to selected order by fields
                    selectedOrderByFields.append(orderByFields[indexPath.row])
                }
                else {
                    //
                    // Set the accessory type to none
                    cell.accessoryType = .none
                    
                    // Remove field from the selected order by fields
                    let index = selectedOrderByFields.index(of: orderByFields[indexPath.row])
                    selectedOrderByFields.remove(at: index!)
                }
            }
        }
        
        // Reload order by fields section
        tableView.reloadSections(IndexSet(integer: 2), with: .automatic)
    }
}
