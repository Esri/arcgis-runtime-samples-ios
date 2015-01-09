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

class CustomHybridViewController: UIViewController {

    @IBOutlet weak var hybridView:AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.userInteractionEnabled = true
        self.view.alpha = 0.9
        
        //initialize the satellite imagery layer
        let satelliteImageryLayer = AGSTiledMapServiceLayer(URL: NSURL(string: "http://services.arcgisonline.com/arcgis/rest/services/World_Imagery/MapServer"))
        //add the bing map layer to the hybrid map view
        self.hybridView.addMapLayer(satelliteImageryLayer, withName:"Satellite ")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showHybridMapAtGraphic(graphic:AGSGraphic) {
        //Zoom in to the building footprint
        //Resolution 0.597 = Level 18 of the tiled map service
        self.hybridView.zoomToResolution(0.597, withCenterPoint:graphic.geometry.envelope.center, animated:true)
    }
    
    //MARK: - Action Methods
    
    @IBAction func zoomIn(sender:AnyObject) {
        //zooms in to the next scale
        self.hybridView.zoomIn(true)
    }
    
    @IBAction func zoomOut(sender:AnyObject) {
        //zooms out to the next scale
        self.hybridView.zoomOut(true)
    }

}
