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

class FeatureTemplateInfo {
    var featureType:AGSFeatureType!
    var featureTemplate:AGSFeatureTemplate!
    var featureLayer:AGSFeatureLayer!
}

protocol FeatureTemplatePickerDelegate:class {
    func featureTemplatePickerViewControllerWantsToDismiss(controller:FeatureTemplatePickerViewController)
    func featureTemplatePickerViewController(controller:FeatureTemplatePickerViewController, didSelectFeatureTemplate template:AGSFeatureTemplate, forFeatureLayer featureLayer:AGSFeatureLayer)
}

class FeatureTemplatePickerViewController: UIViewController {
    
    var infos = [FeatureTemplateInfo]()
    @IBOutlet weak var featureTemplateTableView: UITableView!
    weak var delegate:FeatureTemplatePickerDelegate?
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func addTemplatesFromLayer(featureLayer:AGSFeatureLayer) {
                
        let featureTable = featureLayer.featureTable as! AGSServiceFeatureTable
        //if layer contains only templates (no feature types)
        if featureTable.featureTemplates.count > 0 {
            //for each template
            for template in featureTable.featureTemplates {
                let info = FeatureTemplateInfo()
                info.featureLayer = featureLayer
                info.featureTemplate = template
                info.featureType = nil
                
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
                    let info = FeatureTemplateInfo()
                    info.featureLayer = featureLayer
                    info.featureTemplate = template
                    info.featureType = type
                    
                    //add to array
                    self.infos.append(info)
                }
            }
        }
        
        print("infos count :: \(self.infos.count)")
    }
    
    @IBAction func cancelAction() {
        //Notify the delegate that user tried to dismiss the view controller
        self.delegate?.featureTemplatePickerViewControllerWantsToDismiss(self)
    }
    
    //MARK: - table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.infos.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //Get a cell
        let cellIdentifier = "TemplatePickerCell"
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell!
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier)
        }
        cell.selectionStyle = .Blue
        
        //Set its label, image, etc for the template
        let info = self.infos[indexPath.row]
        cell.textLabel?.font = UIFont.systemFontOfSize(12)
        cell.textLabel?.text = info.featureTemplate.name
//        cell.imageView?.image = info.featureLayer.renderer.symb .swatchForFeatureWithAttributes(info.featureTemplate.prototypeAttributes, geometryType: info.featureLayer.geometryType, size: CGSizeMake(20, 20))
        
        return cell
    }
    
    //MARK: - table view delegate
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        //Notify the delegate that the user picked a feature template
        let info = self.infos[indexPath.row]
        self.delegate?.featureTemplatePickerViewController(self, didSelectFeatureTemplate: info.featureTemplate, forFeatureLayer: info.featureLayer)
        
        //unselect the cell
        tableView.cellForRowAtIndexPath(indexPath)?.selected = false
    }
    
}
