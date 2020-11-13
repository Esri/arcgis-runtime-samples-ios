//
// Copyright 2016 Esri.
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
//

import UIKit

protocol VectorStylesViewControllerDelegate: AnyObject {
    func vectorStylesViewController(_ vectorStylesViewController: VectorStylesViewController, didSelectItemWithID itemID: String)
}

class VectorStylesViewController: UITableViewController {
    /// The item IDs of the custom styles.
    var itemIDs: [String] = []
    /// The item ID of the selected style.
    var selectedItemID: String?
    
    weak var delegate: VectorStylesViewControllerDelegate?
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if itemIDs[indexPath.row] == selectedItemID {
            // Select the displayed item.
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemID = itemIDs[indexPath.row]
        delegate?.vectorStylesViewController(self, didSelectItemWithID: itemID)
        // Indicate which cell has been selected.
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // Indicate which cell has been unselected.
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}
