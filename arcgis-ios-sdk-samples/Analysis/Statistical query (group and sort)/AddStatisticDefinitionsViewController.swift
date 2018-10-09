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

protocol AddStatisticDefinitionsViewControllerDelegate: AnyObject {
    func addStatisticDefinitions(_ statisticDefinitions: [AGSStatisticDefinition])
}

class AddStatisticDefinitionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet private var tableView: UITableView!
    @IBOutlet private weak var fieldNamePicker: HorizontalPicker!
    @IBOutlet private weak var statisticTypePicker: HorizontalPicker!
    @IBOutlet private var tableNavigationItem: UINavigationItem!
    
    public var fieldNames = [String]()
    public var statisticDefinitions = [AGSStatisticDefinition]()
    private var statisticTypes = ["Average", "Count", "Maximum", "Minimum", "StandardDeviation", "Sum", "Variance"]

    // Delegate
    weak var delegate: AddStatisticDefinitionsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup UI Controls
        setupUI()
    }
    
    private func setupUI() {
        // Add picker options
        fieldNamePicker.options = fieldNames
        statisticTypePicker.options =  statisticTypes
        
    }
    
    //MARK: - TableView data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return statisticDefinitions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StatisticDefinitionCell", for: indexPath)
        if statisticDefinitions.count > 0 {
            let statisticDefinition = statisticDefinitions[indexPath.row]
            let statisticTypeString = statisticTypes[statisticDefinition.statisticType.rawValue]
            let text = "\(statisticDefinition.onFieldName) (\(statisticTypeString))"
            cell.textLabel?.text = text
        }
        return cell
    }
    
    // MARK: - Actions
    
    @IBAction func addStatisticDefinitionAction(_ sender: Any) {
        // Add statistic definition
        if let statisticType = AGSStatisticType(rawValue: statisticTypePicker.selectedIndex) {
            let fieldName = fieldNamePicker.options[fieldNamePicker.selectedIndex]
            let statisticDefinition = AGSStatisticDefinition(onFieldName: fieldName, statisticType: statisticType, outputAlias: nil)
            statisticDefinitions.append(statisticDefinition)

            // Reload table
            tableView.reloadData()
        }
        else {
            print("Unable to determine AGSStatisticType from raw value \(statisticTypePicker.selectedIndex).")
        }
    }
    
    @IBAction private func doneAction() {
        // Fire delegate
        delegate?.addStatisticDefinitions(statisticDefinitions)
        
        // Dismiss view controller
        dismiss(animated: true, completion: nil)
    }
}
