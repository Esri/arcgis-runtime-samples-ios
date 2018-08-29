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

protocol FeatureTemplatePickerDelegate:class {
    func featureTemplatePickerViewControllerWantsToDismiss(_ controller:FeatureTemplatePickerViewController)
    func featureTemplatePickerViewController(_ controller:FeatureTemplatePickerViewController, didSelectFeatureTemplate template:AGSFeatureTemplate, forFeatureLayer featureLayer:AGSFeatureLayer)
}

class FeatureTemplatePickerViewController: UITableViewController {
    weak var delegate:FeatureTemplatePickerDelegate?
    
    private struct FeatureTemplateInfo {
        var featureLayer: AGSFeatureLayer!
        var featureTemplate: AGSFeatureTemplate!
    }
    
    private var infos = [FeatureTemplateInfo]()
    
    func addTemplatesFromLayer(_ featureLayer:AGSFeatureLayer) {
                
        let featureTable = featureLayer.featureTable as! AGSServiceFeatureTable
        //if layer contains only templates (no feature types)
        if !featureTable.featureTemplates.isEmpty {
            //for each template
            for template in featureTable.featureTemplates {
                let info = FeatureTemplateInfo(
                    featureLayer: featureLayer,
                    featureTemplate: template
                )
                //add to array
                self.infos.append(info)
            }
        }
            //otherwise if layer contains feature types
        else  {
            //for each type
            for type in featureTable.featureTypes {
                //for each temple in type
                for template in type.templates {
                    let info = FeatureTemplateInfo(
                        featureLayer: featureLayer,
                        featureTemplate: template
                    )
                    //add to array
                    self.infos.append(info)
                }
            }
        }
    }
    
    @IBAction func cancelAction() {
        //Notify the delegate that user tried to dismiss the view controller
        self.delegate?.featureTemplatePickerViewControllerWantsToDismiss(self)
    }
    
    //MARK: - table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.infos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Get a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "TemplatePickerCell", for: indexPath)
        
        //Set its label, image, etc for the template
        let info = self.infos[indexPath.row]
        cell.textLabel?.text = info.featureTemplate.name
        
        return cell
    }
    
    //MARK: - table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Notify the delegate that the user picked a feature template
        let info = self.infos[indexPath.row]
        self.delegate?.featureTemplatePickerViewController(self, didSelectFeatureTemplate: info.featureTemplate, forFeatureLayer: info.featureLayer)
        
        //unselect the cell
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
