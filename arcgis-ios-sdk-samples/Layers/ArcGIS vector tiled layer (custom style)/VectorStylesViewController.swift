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

protocol VectorStylesVCDelegate: AnyObject {
    func vectorStylesViewController(_ vectorStylesViewController: VectorStylesViewController, didSelectItemWithID itemID: String)
}

class VectorStylesViewController: UITableViewController {
    /// The item IDs of the custom styles.
    var itemIDs: [String] = []
    /// The item ID of the selected style.
    var selectedItemID: String?
    
    weak var delegate: VectorStylesVCDelegate?
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        // Indicate the displayed item.
        cell.accessoryType = itemIDs[indexPath.row] == selectedItemID ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemID = itemIDs[indexPath.row]
        delegate?.vectorStylesViewController(self, didSelectItemWithID: itemID)
        // Indicate which cell has been selected.
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        if let previousItemID = selectedItemID, let previousRow = itemIDs.firstIndex(of: previousItemID) {
            tableView.cellForRow(at: IndexPath(row: previousRow, section: 0))?.accessoryType = .none
        }
        selectedItemID = itemID
    }
}
