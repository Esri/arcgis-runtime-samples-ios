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

protocol OrderByFieldsViewControllerDelegate: AnyObject {
    func setOrdering(with orderByFields: [AGSOrderBy])
}

class OrderByFieldsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

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
            messageLabel.text = "Only selected Group By Fields are valid for Order By Fields so please select Group By Fields first."
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = .center;
            messageLabel.font = UIFont.systemFont(ofSize: 20)
            messageLabel.sizeToFit()
            tableView.backgroundView?.backgroundColor = .white
            tableView.backgroundView = messageLabel;
        }
        return orderByFields.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "OrderByFieldsCell", for: indexPath)
        
        // Set text
        let orderByField = orderByFields[indexPath.row]
        let sortOrderString = stringFor(sortOrder: orderByField.sortOrder)
        let text = "\(orderByField.fieldName) (\(sortOrderString))"
        cell.textLabel?.text = text
        
        // Set image
        cell.imageView?.image = imageFor(sortOrder: orderByField.sortOrder)
        
        // Make image tappable
        cell.imageView?.isUserInteractionEnabled = true;
        cell.imageView?.tag = indexPath.row;
        let imageViewTapGesture = UITapGestureRecognizer()
        imageViewTapGesture.addTarget(self, action: #selector(imageViewWasTouched(_:)))
        cell.imageView?.addGestureRecognizer(imageViewTapGesture)
        
        // Set accessory type
        if selectedOrderByFields.contains(where: { $0.fieldName == orderByField.fieldName }) {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // MARK: - TableView delegates
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Deselect row
        tableView.deselectRow(at: indexPath, animated: false)
        
        // Get the cell
        if let cell = tableView.cellForRow(at: indexPath) {
            if cell.accessoryType == .none {
                // Set the accessory type to checkmark
                cell.accessoryType = .checkmark
                
                // Add field to selected order by fields
                let orderByField = orderByFields[indexPath.row]
                selectedOrderByFields.append(orderByField)
            }
            else {
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
        // Fire delegate
        delegate?.setOrdering(with: selectedOrderByFields)
        
        // Dismiss view controller
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Gesture Recognizer
    
    @objc func imageViewWasTouched(_ sender: UITapGestureRecognizer) {
        let imageView = sender.view as! UIImageView
        let indexPath = IndexPath(row: imageView.tag, section: 0)
        let cell = tableView.cellForRow(at: indexPath)
        let orderByField = orderByFields[imageView.tag]
        if orderByField.sortOrder == .ascending {
            orderByField.sortOrder = .descending
            cell?.imageView?.image = imageFor(sortOrder: orderByField.sortOrder)
            let sortOrderString = stringFor(sortOrder: orderByField.sortOrder)
            let text = "\(orderByField.fieldName) (\(sortOrderString))"
            cell?.textLabel?.text = text
        }
        else {
            orderByField.sortOrder = .ascending
            cell?.imageView?.image = imageFor(sortOrder: orderByField.sortOrder)
            let sortOrderString = stringFor(sortOrder: orderByField.sortOrder)
            let text = "\(orderByField.fieldName) (\(sortOrderString))"
            cell?.textLabel?.text = text
        }
        
        // Reload row
        tableView.reloadRows(at: [indexPath], with: .automatic)
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
    
    private func imageFor(sortOrder: AGSSortOrder) -> UIImage {
        switch sortOrder {
        case .ascending:
            return UIImage(named: "Ascending")!
        case .descending:
            return UIImage(named: "Descending")!
        }
    }
}
