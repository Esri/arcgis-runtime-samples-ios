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
    var itemIDs: [String] = []
    var selectedItemID: String?
    
    weak var delegate: VectorStylesVCDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedItemID = selectedItemID,
            let row = itemIDs.firstIndex(of: selectedItemID) {
            let indexPath = IndexPath(row: row, section: 0)
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            let cell = tableView.cellForRow(at: indexPath)
            cell?.accessoryType = .checkmark
        }
    }
    
    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemID = itemIDs[indexPath.row]
        delegate?.vectorStylesViewController(self, didSelectItemWithID: itemID)
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}
