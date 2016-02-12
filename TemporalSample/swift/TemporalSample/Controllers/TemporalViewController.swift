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

let kTiledMapServiceURL = "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"
let kFeatureServiceURL = "http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/Earthquakes/EarthquakesFromLastSevenDays/FeatureServer/0"

class TemporalViewController: UIViewController, AGSLayerCalloutDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var segmentControl:UISegmentedControl!
    var today:NSDate!
    var calloutTemplate:AGSCalloutTemplate!
    var featureLyr:AGSFeatureLayer!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Add an ArcGIS Online layer as basemap
        let tiledLyr = AGSTiledMapServiceLayer(URL: NSURL(string: kTiledMapServiceURL))
        self.mapView.addMapLayer(tiledLyr, withName:"Base map Layer")
        
        //Add Earthquakes layer showing earthquakes from last 7 days
        //Using Snapshot mode because number of earthquakes won't be too large (hopefully)
        self.featureLyr = AGSFeatureLayer(URL: NSURL(string: kFeatureServiceURL), mode:.Snapshot)
        self.featureLyr.outFields = ["*"]
        self.featureLyr.calloutDelegate = self
        self.mapView.addMapLayer(self.featureLyr, withName:"Earthquakes Layer")
        
        
 
        //Customizing the callout look
        self.mapView.callout.accessoryButtonHidden = true
        self.mapView.callout.color = UIColor(red: 0.475, green:0.545, blue:0.639, alpha:1)
        self.mapView.callout.titleColor = UIColor.whiteColor()
        self.mapView.callout.detailColor = UIColor.whiteColor()
        
        //Dynamically assigning values to the segmented control
        //Using the past 5 days
        self.today = NSDate()
        self.assignValuesToSegmentedControlEndingWith(self.today)
        
        self.mapView.enableWrapAround()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func datePicked() {
        //if final segment
        if self.segmentControl.selectedSegmentIndex == self.segmentControl.numberOfSegments-1 {
            //Show all earthquakes
            self.mapView.timeExtent = nil
        }
        else {
            //Show earthquakes from selected date
            let calendar = NSCalendar.currentCalendar()
            
            var offset = NSDateComponents()
            
            //Based on selected segment, find the start of the desired date
            offset.day = -self.segmentControl.selectedSegmentIndex
            if let picked =  calendar.dateByAddingComponents(offset, toDate:self.today, options:NSCalendarOptions.MatchFirst) {
                offset =  calendar.components([NSCalendarUnit.Hour, .Minute, .Second], fromDate:picked)
                
                let seconds = offset.second + 60 * offset.minute + 3600 * offset.hour
                let diff = picked.timeIntervalSinceReferenceDate - Double(seconds)
                let start = NSDate(timeIntervalSinceReferenceDate: diff)
                
                //Also, find the end of the desired date
                offset = NSDateComponents()
                offset.day = 1
                let end =  calendar.dateByAddingComponents(offset, toDate:start, options:NSCalendarOptions.MatchFirst)
                
                //Set a time extent ranging from start to end
                let extent = AGSTimeExtent(start: start, end:end)
                self.mapView.timeExtent = extent
            }
            
            //hide callout incase it was pointing to an earthquake from another date
            self.mapView.callout.hidden = true
            
        }
    }
    
    //MARK: - AGSLayerCalloutDeleage methods
    func callout(callout: AGSCallout!, willShowForFeature feature: AGSFeature!, layer: AGSLayer!, mapPoint: AGSPoint!) -> Bool {
        let graphic = feature as! AGSGraphic
        //title text for callout
        
        let title = String(format: "Magnitude: %.1f", graphic.attributeAsDoubleForKey("magnitude", exists:nil))
        callout.title  = title
        
        let detail = String(format: "Depth: %.1f km, %@", graphic.attributeAsDoubleForKey("depth", exists:nil), graphic.attributeAsStringForKey("region"))
        callout.detail = detail
        return true
    }
    
    func assignValuesToSegmentedControlEndingWith(today:NSDate) {
        let calendar = NSCalendar.currentCalendar()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "dd MMM" //Ex: 05 Jan
        
        let offset = NSDateComponents()
        
        //segmentControl.numberOfSegments = 6 in the xib file
        //Assigning values of 5 recent days to the first 5 segments
        for var i=0; i < self.segmentControl.numberOfSegments-1 ; i++ {
            offset.day = -i
            let temp = calendar.dateByAddingComponents(offset, toDate:today, options:NSCalendarOptions.MatchFirst)
            let str = formatter.stringFromDate(temp!)
            self.segmentControl.setTitle(str, forSegmentAtIndex:i)
        }
        //Assigning value ALL to last segment
        self.segmentControl.setTitle("All", forSegmentAtIndex:self.segmentControl.numberOfSegments-1)
        self.segmentControl.selectedSegmentIndex = self.segmentControl.numberOfSegments-1
    }
}
