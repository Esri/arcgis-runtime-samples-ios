// Copyright 2014 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm

import UIKit
import ArcGIS

class FeatureTemplateInfo {
    var featureType:AGSFeatureType!
    var featureTemplate:AGSFeatureTemplate!
    var featureLayer:AGSFeatureLayer!
}

protocol FeatureTemplateDelegate:class {
    func featureTemplatePickerViewControllerWasDismissed(controller:FeatureTemplatePickerController)
    func featureTemplatePickerViewController(controller:FeatureTemplatePickerController, didSelectFeatureTemplate template:AGSFeatureTemplate, forFeatureLayer featureLayer:AGSFeatureLayer)
}

class FeatureTemplatePickerController: UIViewController {

    var infos = [FeatureTemplateInfo]()
    @IBOutlet weak var featureTemplateTableView: UITableView!
    //TODO: check for weak or strong
    weak var delegate:FeatureTemplateDelegate?
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func addTemplatesFromLayer(layer:AGSFeatureLayer) {
        
        //if layer contains only templates (no feature types)
        if layer.templates != nil && layer.templates.count > 0 {
            //for each template
            for template in layer.templates as! [AGSFeatureTemplate] {
                let info = FeatureTemplateInfo()
                info.featureLayer = layer
                info.featureTemplate = template
                info.featureType = nil
                
                //add to array
                self.infos.append(info)
            }
        }
        //otherwise if layer contains feature types
        else  {
            //for each type
            for type in layer.types as! [AGSFeatureType] {
                //for each temple in type
                for template in type.templates as! [AGSFeatureTemplate] {
                    let info = FeatureTemplateInfo()
                    info.featureLayer = layer
                    info.featureTemplate = template
                    info.featureType = type
                    
                    //add to array
                    self.infos.append(info)
                }
            }
        }
    }
    
    @IBAction func dismiss() {
        //Notify the delegate that user tried to dismiss the view controller
        self.delegate?.featureTemplatePickerViewControllerWasDismissed(self)
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
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier)!
        
        //Set its label, image, etc for the template
        let info = self.infos[indexPath.row]
        cell.textLabel?.text = info.featureTemplate.name
        cell.imageView?.image = info.featureLayer.renderer.swatchForFeatureWithAttributes(info.featureTemplate.prototypeAttributes, geometryType: info.featureLayer.geometryType, size: CGSizeMake(20, 20))
        
        return cell
    }
    
    //MARK: - table view delegate
    
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        //Notify the delegate that the user picked a feature template
        let info = self.infos[indexPath.row]
        self.delegate!.featureTemplatePickerViewController(self, didSelectFeatureTemplate: info.featureTemplate, forFeatureLayer: info.featureLayer)
        
        //unselect the cell
        tableView.cellForRowAtIndexPath(indexPath)?.selected = false
    }

}
