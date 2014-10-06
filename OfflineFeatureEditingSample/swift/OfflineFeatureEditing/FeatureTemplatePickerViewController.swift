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

import Foundation
import ArcGIS
import UIKit

class FeatureTemplatePickerInfo {
    var featureType:AGSFeatureType!
    var featureTemplate:AGSFeatureTemplate!
    var source:AGSGDBFeatureSourceInfo!
    var renderer:AGSRenderer!
}

protocol FeatureTemplatePickerDelegate:class {
    func featureTemplatePickerViewControllerWasDismissed(controller:FeatureTemplatePickerViewController)
    func featureTemplatePickerViewController(controller:FeatureTemplatePickerViewController, didSelectFeatureTemplate template:AGSFeatureTemplate, forLayer layer:AGSGDBFeatureSourceInfo)
}

class FeatureTemplatePickerViewController:UIViewController, UITableViewDataSource, UITableViewDelegate {

    var infos = [FeatureTemplatePickerInfo]()
    @IBOutlet weak var featureTemplateTableView: UITableView!
    weak var delegate:FeatureTemplatePickerDelegate?
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func addTemplatesForLayersInMap(mapView:AGSMapView) {
        for layer in mapView.mapLayers {
            if layer is AGSFeatureLayer {
                self.addTemplatesFromSource(layer as AGSFeatureLayer, renderer: (layer as AGSFeatureLayer).renderer)
            }
            else if layer is AGSFeatureTableLayer {
                self.addTemplatesFromSource(((layer as AGSFeatureTableLayer).table as AGSGDBFeatureTable), renderer: (layer as AGSFeatureTableLayer).renderer)
            }
        }
    }
    
    func addTemplatesFromSource(source:AGSGDBFeatureSourceInfo, renderer:AGSRenderer) {
        
        if source.types != nil && source.types.count > 0 {
            //for each type
            for type in source.types as [AGSFeatureType] {
                //for each temple in type
                for template in type.templates as [AGSFeatureTemplate] {
                    let info = FeatureTemplatePickerInfo()
                    info.source = source
                    info.renderer = renderer
                    info.featureTemplate = template
                    info.featureType = type
                    
                    //add to array
                    self.infos.append(info)
                }
            }
        }
        //if layer contains only templates (no feature types)
        else if source.templates != nil {
            //for each template
            for template in source.templates as [AGSFeatureTemplate] {
                let info = FeatureTemplatePickerInfo()
                info.source = source
                info.renderer = renderer
                info.featureTemplate = template
                info.featureType = nil
                
                //add to array
                self.infos.append(info)
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
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell!
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier)
        }
        
        cell.selectionStyle = .Blue
        
        //Set its label, image, etc for the template
        let info = self.infos[indexPath.row]
        cell.textLabel?.font = UIFont.systemFontOfSize(12)
        cell.textLabel?.text = info.featureTemplate.name
        cell.imageView?.image = info.renderer.swatchForFeatureWithAttributes(info.featureTemplate.prototypeAttributes, geometryType: info.source.geometryType, size: CGSizeMake(20, 20))
        
        return cell
    }
    
    //MARK: - table view delegate
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Notify the delegate that the user picked a feature template
        let info = self.infos[indexPath.row]
        println("\(self), \(info.featureTemplate), \(info.source), \(self.delegate)")
        self.delegate?.featureTemplatePickerViewController(self , didSelectFeatureTemplate: info.featureTemplate, forLayer: info.source)
        
        //unselect the cell
        tableView.cellForRowAtIndexPath(indexPath)?.selected = false
    }
}