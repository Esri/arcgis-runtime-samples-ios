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

protocol OrderByFieldsViewControllerDelegate: class {
    func orderByFieldsViewController(_ orderByFieldsViewController: OrderByFieldsViewController, selectedOrderByFields: [AGSOrderBy])
}

class OrderByFieldsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    //
    // Outlets
    @IBOutlet private var tableView: UITableView!
    @IBOutlet private var tableNavigationItem: UINavigationItem!
    
    // List of fields and selected fields
    public var orderByFields = [AGSOrderBy]()
    public var selectedOrderByFields = [AGSOrderBy]()
    
    // Delegate
    weak var delegate: OrderByFieldsViewControllerDelegate?
    
    // MARK: - View Methods

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - TableView data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if orderByFields.count > 0 {
            tableView.backgroundView = nil
            return orderByFields.count
        } else {
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height))
            messageLabel.text = "Please select group by fields first."
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = .center;
            messageLabel.font = UIFont(name: "HelveticaNeue", size: 20.0)!
            messageLabel.sizeToFit()
            tableView.backgroundView = messageLabel;
        }
        return orderByFields.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupByFieldsCell")!
        let orderByField = orderByFields[indexPath.row]
        cell.textLabel?.text = orderByField.fieldName
        if selectedOrderByFields.contains(orderByField) {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    // MARK: - TableView delegates
    
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
                
                // Add field to selected order by fields
                let orderByField = orderByFields[indexPath.row]
                selectedOrderByFields.append(orderByField)
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
    
    // MARK: - Actions
    
    @IBAction private func doneAction() {
        //
        // Fire delegate
        delegate?.orderByFieldsViewController(self, selectedOrderByFields: selectedOrderByFields)
        
        // Dismiss view controller
        dismiss(animated: true, completion: nil)
    }
}
