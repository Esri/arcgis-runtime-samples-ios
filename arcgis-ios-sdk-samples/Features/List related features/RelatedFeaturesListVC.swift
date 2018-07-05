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

class RelatedFeaturesListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView:UITableView!
    @IBOutlet var label:UILabel!
    
    //results required for display
    var results:[AGSRelatedFeatureQueryResult]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let result = results?[0] {
            self.label.text = result.feature?.attributes["UNIT_NAME"] as? String ?? "Origin Feature"
        }
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 44
    }
    
    //MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.results?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        let result = self.results[section]
        if let tableName = result.relatedTable?.tableName {
            return "\(tableName)"
        }
        else {
            return "Related table \(section + 1)"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let result = results[section]
        return result.featureEnumerator().allObjects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let result = self.results[indexPath.section]
        let feature = result.featureEnumerator().allObjects[indexPath.row]
        
        let displayFieldName = result.relatedTable!.layerInfo!.displayFieldName
        let displayFieldValue = feature.attributes[displayFieldName]!
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RelatedFeatureCell", for: indexPath)
        
        cell.textLabel?.text = "\(displayFieldValue)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.tintColor = .white
    }

}
