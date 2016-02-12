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

class ViewController: UIViewController {
    
    
    @IBOutlet weak var label:UILabel!
    @IBOutlet weak var northArrowImage:UIImageView!
    @IBOutlet weak var autoPanModeControl:UISegmentedControl!
    @IBOutlet weak var mapView:AGSMapView!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mapUrl = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer")
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        //Listen to KVO notifications for map gps's autoPanMode property
        self.mapView.locationDisplay.addObserver(self, forKeyPath: "autoPanMode", options: .New, context: nil)
        
        //Listen to KVO notifications for map rotationAngle property
        self.mapView.addObserver(self, forKeyPath: "rotationAngle", options: .New, context: nil)
        
        //to display actual images in iOS 7 for segmented control
        let index = self.autoPanModeControl.numberOfSegments
        for var i = 0; i < index; i++ {
            if let image = self.autoPanModeControl.imageForSegmentAtIndex(i) {
                let newImage = image.imageWithRenderingMode(.AlwaysOriginal)
                self.autoPanModeControl.setImage(newImage, forSegmentAtIndex:i)
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        //if autoPanMode changed
        if keyPath == "autoPanMode" {
            //Update the label to reflect which autoPanMode is active
            var mode:String!
            switch (self.mapView.locationDisplay.autoPanMode) {
            case .Off:
                mode = "Off"
            case .Default:
                mode = "Default"
            case .Navigation:
                mode = "Navigation"
            case .CompassNavigation:
                mode = "Compass Navigation"
            }
            self.label.textColor = UIColor.whiteColor()
            self.label.text = "AutoPan Mode: \(mode)"
            
            //Un-select the segments when autoPanMode changes to OFF
            //Also, restore north-up map rotation
            if self.mapView.locationDisplay.autoPanMode == .Off {
                self.autoPanModeControl.selectedSegmentIndex = -1
            }
            
            //Also, restore north-up map rotation if Auto pan goes OFF or back to Default
            if(self.mapView.locationDisplay.autoPanMode == .Off || self.mapView.locationDisplay.autoPanMode == .Default){
                self.mapView.setRotationAngle(0, animated:true)
                self.northArrowImage.transform = CGAffineTransformIdentity
            }
        }
            //if rotationAngle changed
        else if keyPath == "rotationAngle" {
            if self.mapView.locationDisplay.autoPanMode != .Off || self.mapView.locationDisplay.autoPanMode != .Default {
                let angle = -(self.mapView.rotationAngle*3.14)/180
                let transform = CGAffineTransformMakeRotation(CGFloat(angle))
                self.northArrowImage.transform = transform
            }
        }
            
            //if mapscale changed
        else if keyPath == "mapScale" {
            if self.mapView.mapScale < 5000 {
                self.mapView.zoomToScale(50000, withCenterPoint:nil, animated:true)
                self.mapView.removeObserver(self, forKeyPath:"mapScale")
            }
        }
    }
    
    //MARK: - Action methods
    
    @IBAction func autoPanModeChanged(sender:UISegmentedControl) {
        //Start the map's gps if it isn't enabled already
        if !self.mapView.locationDisplay.dataSourceStarted {
            self.mapView.locationDisplay.startDataSource()
        }
        
        //Listen to KVO notifications for map scale property
        self.mapView.addObserver(self, forKeyPath: "mapScale", options: .New, context: nil)
        
        //Set the appropriate AutoPan mode
        switch self.autoPanModeControl.selectedSegmentIndex {
        case 0:
            self.mapView.locationDisplay.autoPanMode = .Default
            //Set a wander extent equal to 75% of the map's envelope
            //The map will re-center on the location symbol only when
            //the symbol moves out of the wander extent
            self.mapView.locationDisplay.wanderExtentFactor = 0.75
        case 1:
            self.mapView.locationDisplay.autoPanMode = .Navigation
            //Position the location symbol near the bottom of the map
            //A value of 1 positions it at the top edge, and 0 at bottom edge
            self.mapView.locationDisplay.navigationPointHeightFactor = 0.15
        case 2:
            self.mapView.locationDisplay.autoPanMode = .CompassNavigation
            //Position the location symbol in the center of the map
            self.mapView.locationDisplay.navigationPointHeightFactor = 0.5
            
        default:
            break
        }
    }
}

