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

import UIKit
import ArcGIS

class FeatureLayersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView:UITableView!
    
    var featureLayerInfos:[AGSIDInfo]! {
        didSet {
            self.tableView?.reloadData()
        }
    }
    var selectedLayerIds = [Int]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.featureLayerInfos?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeatureLayerCell", for: indexPath)
        
        let layerInfo = self.featureLayerInfos[indexPath.row]
        cell.textLabel?.text = layerInfo.name
        
        //accessory view
        if self.selectedLayerIds.contains(layerInfo.id) {
            cell.accessoryType = .checkmark
        }
        else {
            cell.accessoryType = .none
        }
        
        cell.backgroundColor = .clear
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let layerInfo = self.featureLayerInfos[indexPath.row]
        
        if let index = self.selectedLayerIds.index(of: layerInfo.id) {
            self.selectedLayerIds.remove(at: index)
        }
        else {
            self.selectedLayerIds.append(layerInfo.id)
        }
        
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}
