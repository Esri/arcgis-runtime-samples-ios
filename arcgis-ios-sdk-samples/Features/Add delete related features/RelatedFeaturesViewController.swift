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

class RelatedFeaturesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet private var tableView:UITableView!
    @IBOutlet private var featureLabel:UILabel!
    
    var originFeature:AGSArcGISFeature!
    var originFeatureTable:AGSServiceFeatureTable!
    
    private var relationshipInfo:AGSRelationshipInfo!
    private var relatedFeatures:[AGSFeature]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //query for related features and populate the table
        self.queryRelatedFeatures()
        
        //Displaying information on selected park using the field UNIT_NAME, name of the park
        self.featureLabel.text = self.originFeature.attributes["UNIT_NAME"] as? String ?? "Origin Feature"
    }
    
    private func queryRelatedFeatures() {
        
        //get relationship info
        //feature table's layer info has an array of relationshipInfos, one for each relationship
        //in this case there is only one describing the 1..M relationship between parks and species
        guard let relationshipInfo = self.originFeatureTable.layerInfo?.relationshipInfos[0] else {
            
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
        self.originFeatureTable.queryRelatedFeatures(for: self.originFeature, parameters: parameters) { [weak self] (results:[AGSRelatedFeatureQueryResult]?, error:Error?) in
            
            guard error == nil else {
                self?.presentAlert(error: error!)
                return
            }
            
            //dismiss progress hud
            SVProgressHUD.dismiss()
            
            if let results = results, results.count > 0 {
                
                //save the related features to display in the table view
                self?.relatedFeatures = results[0].featureEnumerator().allObjects
                
                //reload table view to reflect changes
                self?.tableView.reloadData()
            }
        }
    }
    
    private func addRelatedFeature() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Adding feature")
        
        //get related table using relationshipInfo
        let relatedTable = self.originFeatureTable.relatedTables(with: self.relationshipInfo)![0] as! AGSServiceFeatureTable
        
        //new feature
        let feature = relatedTable.createFeature(attributes: ["Scientific_name" : "New species"], geometry: nil) as! AGSArcGISFeature
        
        //relate new feature to origin feature
        feature.relate(to: self.originFeature)
        
        //add new feature to related table
        relatedTable.add(feature) { [weak self] (error) in
            
            guard error == nil else {
                self?.presentAlert(error: error!)
                return
            }
            
            //apply edits
            self?.applyEdits()
        }
    }
    
    private func deleteRelatedFeature(_ feature: AGSFeature) {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Deleting feature")
        
        //get related table using relationshipInfo
        let relatedTable = self.originFeatureTable.relatedTables(with: self.relationshipInfo)![0] as! AGSServiceFeatureTable
        
        //delete feature from related table
        relatedTable.delete(feature) { [weak self] (error) in
            
            guard error == nil else {
                self?.presentAlert(error: error!)
                return
            }
            
            //apply edits
            self?.applyEdits()
        }
    }
    
    private func applyEdits() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Applying edits")
        
        //get the related table using the relationshipInfo
        let relatedTable = self.originFeatureTable.relatedTables(with: self.relationshipInfo)![0] as! AGSServiceFeatureTable
        
        relatedTable.applyEdits { [weak self] (results:[AGSFeatureEditResult]?, error:Error?) in
            
            guard error == nil else {
                //show error
                self?.presentAlert(error: error!)
                return
            }
            
            //query to update features
            self?.queryRelatedFeatures()
        }
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.relatedFeatures?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RelatedFeatureCell", for: indexPath)
        
        let relatedFeature = self.relatedFeatures[indexPath.row]
        
        //display value for Scientific_Name field in the cell
        cell.textLabel?.text = relatedFeature.attributes["Scientific_Name"] as? String
        
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            //delete related feature
            let relatedFeature = self.relatedFeatures[indexPath.row]
            self.deleteRelatedFeature(relatedFeature)
        }
    }

    //MARK: - Actions
    
    @IBAction private func addAction() {
        
        self.addRelatedFeature()
    }
    
    @IBAction private func doneAction() {

        //dismiss view controller
        self.dismiss(animated: true, completion: nil)
    }
}
