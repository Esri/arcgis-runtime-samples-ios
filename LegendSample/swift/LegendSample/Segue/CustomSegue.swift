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

class CustomSegue: UIStoryboardSegue {
    
    var rect:CGRect!
    var view:UIView!
    var popOverController:UIPopoverController!
    
    override func perform() {
        //in case of iPad present new view as pop over
        if AGSDevice.currentDevice().isIPad() {
            self.popOverController.presentPopoverFromRect(self.rect, inView:self.view, permittedArrowDirections:.Any, animated:true)
        }
            //in case of iPhone present view as a modal view
        else {
            self.sourceViewController.presentViewController(self.destinationViewController, animated:true, completion:nil)
        }
    }
}
