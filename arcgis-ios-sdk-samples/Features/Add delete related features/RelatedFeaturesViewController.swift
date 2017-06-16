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
    
    var originFeature:AGSArcGISFeature!
    var originFeatureTable:AGSServiceFeatureTable!
    
    private var relationshipInfo:AGSRelationshipInfo!
    private var relatedFeatures:[AGSFeature]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //query for related features and populate the table
        self.queryRelatedFeatures()
    }
    
    private func queryRelatedFeatures() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Querying related features", maskType: .gradient)
        
        //query related features for orgin feature
        self.originFeatureTable.queryRelatedFeatures(for: self.originFeature) { [weak self] (results, error) in
            
            guard error == nil else {
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
                return
            }
            
            //dismiss progress hud
            SVProgressHUD.dismiss()
            
            if let results = results, results.count > 0 {
                
                self?.relatedFeatures = results[0].featureEnumerator().allObjects
                self?.relationshipInfo = results[0].relationshipInfo
                
                //reload table
                self?.tableView.reloadData()
            }
        }
    }
    
    private func addRelatedFeature() {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Adding feature", maskType: .gradient)
        
        //get related table using relationshipInfo
        let relatedTable = self.originFeatureTable.relatedTables(with: self.relationshipInfo)![0] as! AGSServiceFeatureTable
        
        //new feature
        let feature = relatedTable.createFeature(attributes: ["Scientific_name" : "New specie"], geometry: nil) as! AGSArcGISFeature
        
        //relate new feature to origin feature
        feature.relate(to: self.originFeature)
        
        //add new feature to related table
        relatedTable.add(feature) { [weak self] (error) in
            
            guard error == nil else {
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
                return
            }
            
            //query related features to update the table
            self?.queryRelatedFeatures()
        }
    }
    
    private func deleteRelatedFeature(_ feature: AGSFeature) {
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Deleting feature", maskType: .gradient)
        
        //get related table using relationshipInfo
        let relatedTable = self.originFeatureTable.relatedTables(with: self.relationshipInfo)![0] as! AGSServiceFeatureTable
        
        //delete feature from related table
        relatedTable.delete(feature) { [weak self] (error) in
            
            guard error == nil else {
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
                return
            }
            
            //query related features to update the table
            self?.queryRelatedFeatures()
        }
    }
    
    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.relatedFeatures?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "RelatedFeatureCell")!
        
        let relatedFeature = self.relatedFeatures[indexPath.row]
        
        //display value for Scientific_Name field in the cell
        cell.textLabel?.text = relatedFeature.attributes["Scientific_Name"] as? String
        
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
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

        //get the related table using the relationshipInfo
        let relatedTable = self.originFeatureTable.relatedTables(with: self.relationshipInfo)![0] as! AGSServiceFeatureTable
        
        //show progress hud
        SVProgressHUD.show(withStatus: "Applying edits", maskType: .gradient)
        
        //apply edits
        relatedTable.applyEdits { [weak self] (featureEditResults, error) in
            
            //dismiss view controller
            self?.dismiss(animated: true, completion: nil)
            
            guard error == nil else {
                SVProgressHUD.showError(withStatus: error!.localizedDescription, maskType: .gradient)
                return
            }
            
            //dismiss progress hud
            SVProgressHUD.dismiss()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
