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

protocol GroupByFieldsViewControllerDelegate: class {
    func setGrouping(with fieldNames: [String])
}

class GroupByFieldsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    //
    // Outlets
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var tableNavigationItem: UINavigationItem!
    
    // List of fields and selected fields
    public var fieldNames = [String]()
    public var selectedFieldNames = [String]()
    
    // Delegate
    weak var delegate: GroupByFieldsViewControllerDelegate?
    
    // MARK: - View Methods

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: - TableView data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fieldNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupByFieldsCell", for: indexPath)
        let fieldName = fieldNames[indexPath.row]
        cell.textLabel?.text = fieldName
        if selectedFieldNames.contains(fieldName) {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    //MARK: - TableView delegates
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //
        // Deselect row
        tableView.deselectRow(at: indexPath, animated: false)
        
        //
        // Get the cell
        if let cell = tableView.cellForRow(at: indexPath) {
            if cell.accessoryType == .none {
                //
                // Set the accessory type to checkmark
                cell.accessoryType = .checkmark
                
                // Add field name to selected group by fields
                let fieldName = fieldNames[indexPath.row]
                selectedFieldNames.append(fieldName)
            }
            else {
                //
                // Set the accessory type to none
                cell.accessoryType = .none
                
                // Remove field from the group by fields
                let index = selectedFieldNames.index(of: fieldNames[indexPath.row])
                selectedFieldNames.remove(at: index!)
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction private func doneAction() {
        //
        // Fire delegate
        delegate?.setGrouping(with: selectedFieldNames)
        
        // Dismiss view controller
        dismiss(animated: true, completion: nil)
    }
}
