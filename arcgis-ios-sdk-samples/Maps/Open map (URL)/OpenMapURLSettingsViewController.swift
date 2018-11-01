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
    
    /// A model for the maps the user may toggle between.
    private struct MapAtURL {
        var title: String
        var thumbnailImage: UIImage
        var id: String
        
        var url: URL? {
            return URL(string: "https://www.arcgis.com/home/item.html?id=\(id)")
        }
    }
    
    private let mapModels: [MapAtURL] = [
        MapAtURL(title: "Housing with Mortgages",
                 thumbnailImage: #imageLiteral(resourceName: "OpenMapURLThumbnail1"),
                 id: "2d6fa24b357d427f9c737774e7b0f977"),
        MapAtURL(title: "USA Tapestry Segmentation",
                 thumbnailImage: #imageLiteral(resourceName: "OpenMapURLThumbnail2"),
                 id: "01f052c8995e4b9e889d73c3e210ebe3"),
        MapAtURL(title: "Geology of United States",
                 thumbnailImage: #imageLiteral(resourceName: "OpenMapURLThumbnail3"),
                 id: "92ad152b9da94dee89b9e387dfe21acd")
    ]
    
    var initialSelectedID: String?
    var onChange: ((URL)->Void)?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let selectedMapIndex = mapModels.firstIndex { (mapAtURL) -> Bool in
            mapAtURL.id == initialSelectedID
        }
        if let selectedMapIndex = selectedMapIndex {
            let selectedIndexPath = IndexPath(row: selectedMapIndex, section: 0)
            tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
            tableView.cellForRow(at: selectedIndexPath)?.accessoryType = .checkmark
        }
    }
    
    //MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapModels.count
    }
    
    //MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MapAtURLCell", for: indexPath)
        
        let mapModel = mapModels[indexPath.row]
        
        cell.textLabel?.text = mapModel.title
        
        cell.imageView?.image = mapModel.thumbnailImage
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.clipsToBounds = true
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let url = mapModels[indexPath.row].url {
            onChange?(url)
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
    
}
