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
import ArcGIS

class RelatedFeaturesViewController: UITableViewController {
    var originFeature: AGSArcGISFeature!
    var originFeatureTable: AGSServiceFeatureTable!
    
    private var relationshipInfo: AGSRelationshipInfo!
    private var relatedFeatures = [AGSFeature]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //query for related features and populate the table
        self.queryRelatedFeatures()
        
        //Displaying information on selected park using the field UNIT_NAME, name of the park
        self.title = self.originFeature.attributes["UNIT_NAME"] as? String ?? "Origin Feature"
    }
    
    private func queryRelatedFeatures() {
        //get relationship info
        //feature table's layer info has an array of relationshipInfos, one for each relationship
        //in this case there is only one describing the 1..M relationship between parks and species
        guard let relationshipInfo = self.originFeatureTable.layerInfo?.relationshipInfos.first else {
            presentAlert(message: "Relationship info not found")
            return
        }
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Querying related features")
        
        //keep for later use
        self.relationshipInfo = relationshipInfo
        
        //initialize related query parameters with relationshipInfo
        let parameters = AGSRelatedQueryParameters(relationshipInfo: relationshipInfo)
        
        //order results by OBJECTID field
        parameters.orderByFields = [AGSOrderBy(fieldName: "OBJECTID", sortOrder: .descending)]
        
        //query for species related to the selected park
        self.originFeatureTable.queryRelatedFeatures(for: self.originFeature, parameters: parameters) { [weak self] (results: [AGSRelatedFeatureQueryResult]?, error: Error?) in
            //dismiss progress hud
            SVProgressHUD.dismiss()
            
            if let error = error {
                self?.presentAlert(error: error)
            } else if let result = results?.first {
                //save the related features to display in the table view
                self?.relatedFeatures = result.featureEnumerator().allObjects
                
                //reload table view to reflect changes
                self?.tableView.reloadData()
            }
        }
    }
    
    private func addRelatedFeature() {
        //get related table using relationshipInfo
        guard let relatedTable = originFeatureTable.relatedTables(with: relationshipInfo)?.first as? AGSServiceFeatureTable,
            //new feature
            let feature = relatedTable.createFeature(attributes: ["Scientific_name": "New species"], geometry: nil) as? AGSArcGISFeature else {
            return
        }
        
        //relate new feature to origin feature
        feature.relate(to: self.originFeature)
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Adding feature")
        
        //add new feature to related table
        relatedTable.add(feature) { [weak self] (error) in
            SVProgressHUD.dismiss()
            
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                //apply edits
                self?.applyEdits()
            }
        }
    }
    
    private func deleteRelatedFeature(_ feature: AGSFeature) {
        //get related table using relationshipInfo
        guard let relatedTable = originFeatureTable.relatedTables(with: relationshipInfo)?.first as? AGSServiceFeatureTable else {
            return
        }
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Deleting feature")
        
        //delete feature from related table
        relatedTable.delete(feature) { [weak self] (error) in
            SVProgressHUD.dismiss()
            
            if let error = error {
                self?.presentAlert(error: error)
            } else {
                //apply edits
                self?.applyEdits()
            }
        }
    }
    
    private func applyEdits() {
        //get the related table using the relationshipInfo
        guard let relatedTable = originFeatureTable.relatedTables(with: relationshipInfo)?.first as? AGSServiceFeatureTable else {
            return
        }
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Applying edits")
        
        relatedTable.applyEdits { [weak self] (_, error) in
            SVProgressHUD.dismiss()
            
            if let error = error {
                //show error
                self?.presentAlert(error: error)
            } else {
                //query to update features
                self?.queryRelatedFeatures()
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return relatedFeatures.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RelatedFeatureCell", for: indexPath)
        
        let relatedFeature = relatedFeatures[indexPath.row]
        
        //display value for Scientific_Name field in the cell
        cell.textLabel?.text = relatedFeature.attributes["Scientific_Name"] as? String
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Related Features (Species)"
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //delete related feature
            let relatedFeature = relatedFeatures[indexPath.row]
            self.deleteRelatedFeature(relatedFeature)
        }
    }

    // MARK: - Actions
    
    @IBAction private func addAction() {
        self.addRelatedFeature()
    }
    
    @IBAction private func doneAction() {
        //dismiss view controller
        self.dismiss(animated: true)
    }
}
