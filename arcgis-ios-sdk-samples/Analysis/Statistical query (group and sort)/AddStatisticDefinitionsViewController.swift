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
    func addStatisticDefinition(_ statisticDefinition: AGSStatisticDefinition)
}

class AddStatisticDefinitionsViewController: UITableViewController {
    @IBOutlet private weak var fieldNameCell: UITableViewCell!
    @IBOutlet private weak var statisticTypeCell: UITableViewCell!
    
    var fieldNames = [String]()
    private var statisticTypes = ["Average", "Count", "Maximum", "Minimum", "StandardDeviation", "Sum", "Variance"]
    
    var fieldName: String? {
        // fieldNames may be empty if the view controller loaded before the data source loaded
        return fieldNameIndex < fieldNames.count ? fieldNames[fieldNameIndex] : nil
    }
    
    var fieldNameIndex: Int = 0 {
        didSet {
            fieldNameCell.detailTextLabel?.text = fieldName
        }
    }
    var statisticType: AGSStatisticType = .average {
        didSet {
            statisticTypeCell.detailTextLabel?.text = statisticTypes[statisticType.rawValue]
        }
    }

    // Delegate
    weak var delegate: AddStatisticDefinitionsViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fieldNameIndex = 0
        statisticType = .average
    }
    
    // MARK: - Actions
    
    @IBAction func addStatisticDefinitionAction(_ sender: Any) {
        // Add statistic definition
        if let fieldName = fieldName {
            let statisticDefinition = AGSStatisticDefinition(onFieldName: fieldName, statisticType: statisticType, outputAlias: nil)
            delegate?.addStatisticDefinition(statisticDefinition)
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch cell {
        case fieldNameCell:
            let controller = OptionsTableViewController(labels: fieldNames, selectedIndex: fieldNameIndex) { (newIndex) in
                self.fieldNameIndex = newIndex
            }
            controller.title = "Field Name"
            show(controller, sender: self)
        case statisticTypeCell:
            let controller = OptionsTableViewController(labels: statisticTypes, selectedIndex: statisticType.rawValue) { (newIndex) in
                self.statisticType = AGSStatisticType(rawValue: newIndex)!
            }
            controller.title = "Statistic Type"
            show(controller, sender: self)
        default:
            break
        }
    }
}
