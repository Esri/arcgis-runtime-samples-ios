//
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
//

import UIKit
import ArcGIS

let kLegendViewControllerSegue = "LegendViewControllerSegue"

class MainViewController: UIViewController, LegendViewControllerDelegate {

    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var infoButton:UIButton!
    
    var legendDataSource:LegendDataSource!
    var legendViewController:LegendViewController!
    var popOverController:UIPopoverController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let mapUrl = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/Specialty/Soil_Survey_Map/MapServer")
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Soils")
        
        //A data source that will hold the legend items for all the map contents (layers)
        self.legendDataSource = LegendDataSource(layerTree: AGSMapContentsTree(mapView:self.mapView, manageLayerVisibility:false))
        
        self.mapView.addMapLayer(AGSDynamicMapServiceLayer(URL: NSURL(string: "http://sampleserver6.arcgisonline.com/arcgis/rest/services/Recreation/MapServer")), withName:"Recreation")
        
        self.mapView.addMapLayer(AGSFeatureLayer(URL: NSURL(string: "http://sampleserver6.arcgisonline.com/arcgis/rest/services/SF311/FeatureServer/0"), mode:.OnDemand), withName:"Incidents")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - LegendViewControllerDelegate methods
    
    func dismissLegend() {
        //in case of iPad dismiss the pop over controller
        if AGSDevice.currentDevice().isIPad() {
            self.popOverController.dismissPopoverAnimated(true)
        }
        else {   //in case of iphone dismiss the modal view controller
            self.dismissViewControllerAnimated(true, completion:nil)
        }
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //check for the segue identifier
        if segue.identifier == kLegendViewControllerSegue {
            //get a reference to the destination controller from the segue
            let controller = segue.destinationViewController as! LegendViewController
            //assign the data source
            controller.legendDataSource = self.legendDataSource
            //assign the delegate
            controller.delegate = self
            
            //using custom segue to handle transitions in iPad and iPhone differently
            //in case of iPad, going to show a pop over controller
            //for which we need to assign three attributes on the segue before performing segue
            //view ::: the view in which the pop over controller will be presented
            //rect ::: the CGRect which will be the target, e.g. the frame of the button which fires the segue
            //popOverController ::: the controller which will be shown as the popOverController
            if AGSDevice.currentDevice().isIPad() {
                
                self.popOverController = UIPopoverController(contentViewController: controller)
                self.popOverController.popoverContentSize = CGSizeMake(200, 600)
                let customSegue = segue as! CustomSegue
                
                customSegue.view = self.view
                customSegue.rect = self.infoButton.frame
                customSegue.popOverController = self.popOverController
            }
        }
    }
}
