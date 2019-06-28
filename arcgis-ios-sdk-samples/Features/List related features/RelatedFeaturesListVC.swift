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

class RelatedFeaturesListVC: UITableViewController {
    //results required for display
    var results = [AGSRelatedFeatureQueryResult]() {
        didSet {
            if let result = results.first {
                title = result.feature?.attributes["UNIT_NAME"] as? String ?? "Origin Feature"
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return results.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let result = results[section]
        if let tableName = result.relatedTable?.tableName {
            return "\(tableName)"
        } else {
            return "Related table \(section + 1)"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let result = results[section]
        return result.featureEnumerator().allObjects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = self.results[indexPath.section]
        let feature = result.featureEnumerator().allObjects[indexPath.row]
        
        let displayFieldName = result.relatedTable!.layerInfo!.displayFieldName
        let displayFieldValue = feature.attributes[displayFieldName]!
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RelatedFeatureCell", for: indexPath)
        
        cell.textLabel?.text = "\(displayFieldValue)"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .white
    }
    
    // MARK: - Actions
    
    @IBAction func doneAction(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}
