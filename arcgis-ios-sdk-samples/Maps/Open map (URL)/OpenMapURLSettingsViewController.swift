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

class OpenMapURLSettingsViewController: UITableViewController {
    var mapOptions: [OpenMapURLViewController.MapAtURL] = []
    var initialSelectedID: String?
    var onChange: ((URL) -> Void)?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let selectedMapIndex = mapOptions.firstIndex { (mapAtURL) -> Bool in
            mapAtURL.portalID == initialSelectedID
        }
        if let selectedMapIndex = selectedMapIndex {
            let selectedIndexPath = IndexPath(row: selectedMapIndex, section: 0)
            tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
            tableView.cellForRow(at: selectedIndexPath)?.accessoryType = .checkmark
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapOptions.count
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MapAtURLCell", for: indexPath)
        
        let mapOption = mapOptions[indexPath.row]
        
        cell.textLabel?.text = mapOption.title
        
        cell.imageView?.image = mapOption.thumbnailImage
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.clipsToBounds = true
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let url = mapOptions[indexPath.row].url {
            onChange?(url)
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}
