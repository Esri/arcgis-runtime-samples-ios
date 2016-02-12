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

let kResultsViewSegueIdentifier = "ResultsViewSegue"
let kRecentViewSegueIdentifier = "RecentViewSegue"

class ViewController: UIViewController, AGSCalloutDelegate, AGSMapViewTouchDelegate, AGSLayerCalloutDelegate, AGSLocatorDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var graphicsLayer:AGSGraphicsLayer!
    var locator:AGSLocator!
    var geocodeResultCalloutTemplate:AGSCalloutTemplate!
    var revGeoResultCalloutTemplate:AGSCalloutTemplate!
    var selectedGraphic:AGSGraphic!
    var magnifierOffset:CGPoint!
    var recentSearches:[String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.recentSearches = ["1455 Market St, San Francisco, CA 94103",
            "2011 Mission St, San Francisco  CA  94110",
            "820 Bryant St, San Francisco  CA  94103",
            "1 Zoo Rd, San Francisco, 944132",
            "1201 Mason Street, San Francisco, CA 94108",
            "151 Third Street, San Francisco, CA 94103",
            "1050 Lombard Street, San Francisco, CA 94109"]
        
        //set the delegate on the mapView so we get notifications for user interaction with callout
        self.mapView.callout.delegate = self
        
        self.mapView.touchDelegate = self
        self.mapView.showMagnifierOnTapAndHold = true
        
        //create an instance of a local tiled layer
        //Add it to the map view
        self.mapView.addMapLayer(AGSLocalTiledLayer(name: "SanFrancisco"))
        
        //create the graphics layer that the geocoding result
        //will be stored in and add it to the map
        self.graphicsLayer = AGSGraphicsLayer()
        self.graphicsLayer.calloutDelegate = self
        
        //create a marker symbol to use in our graphic
        let marker = AGSPictureMarkerSymbol(imageNamed: "BluePushpin.png")
        marker.offset = CGPointMake(9,16)
        marker.leaderPoint = CGPointMake(-9, 11)
        self.graphicsLayer.renderer = AGSSimpleRenderer(symbol: marker)
        
        //add the graphics layer to the map
        self.mapView.addMapLayer(self.graphicsLayer, withName:"Graphics Layer")
        
        //create the AGSLocator with the geo locator URL
        //and set the delegate to self, so we get AGSLocatorDelegate notifications
        self.locator = try! AGSLocator(name: "SanFranciscoLocator")
        self.locator.delegate = self
        
        
        //the amount by which we will need to offset the callout along y-axis
        //from the center of the magnifier to the head of the pushpin
        let pushpinHeadOffset:CGFloat = 60
        
        //the total amount by which we will need to offset the callout along y-axis
        //to show it correctly centered on the pushpin's head in the magnifier
        let img = UIImage(named: "ArcGIS.bundle/Magnifier.png")
        self.magnifierOffset = CGPoint(x: 0, y: -(img!.size.height/2+pushpinHeadOffset))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: - AGSMapViewTouchDelegate methods
    
    func mapView(mapView: AGSMapView!, didTapAndHoldAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        //clear out any previous information in the callout
        self.mapView.callout.title = ""
        self.mapView.callout.detail = ""
        
        //remove any previous results from the layer
        self.graphicsLayer.removeAllGraphics()
        
        //reverse-geocode the location
        self.locator.addressForLocation(mappoint, maxSearchDistance: 25)
        
        //add a graphic where the user began tap&hold & show callout
        self.graphicsLayer.addGraphic(AGSGraphic(geometry: mappoint, symbol:nil, attributes:nil))
        
        //show callout for the graphic taking into account the enlarged map in the magnifier
        self.mapView.callout.showCalloutAt(mappoint, screenOffset:self.magnifierOffset, animated:true)
    }
    
    func mapView(mapView: AGSMapView!, didMoveTapAndHoldAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        //update the graphic & callout location as user moves tap&hold
        (self.graphicsLayer.graphics[0] as! AGSGraphic).geometry = mappoint
        
        //reverse-geocode new location
        self.locator.addressForLocation(mappoint, maxSearchDistance:25)
    }
    
    func mapView(mapView: AGSMapView!, didEndTapAndHoldAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        
        //update callout's position to show it correctly on the regular map display (not enlarged)
        self.mapView.callout.showCalloutAtPoint(mappoint, forFeature: self.graphicsLayer.graphics.first as! AGSFeature, layer: self.graphicsLayer, animated: false)
    }
    
    func startGeocoding() {
        //clear out previous results
        self.graphicsLayer.removeAllGraphics()
        
        //Create the address dictionary with the contents of the search bar
        let addresses =  ["Single Line Input": self.searchBar.text!]
        
        //now request the location from the locator for our address
        self.locator.locationsForAddress(addresses, returnFields:["*"], outSpatialReference:self.mapView.spatialReference)
        
        if !self.recentSearches.contains(self.searchBar.text!) {
            self.recentSearches.insert(self.searchBar.text!, atIndex: 0)
        }
    }
    
    //MARK: - AGSCalloutDelegate
    
    func didClickAccessoryButtonForCallout(callout: AGSCallout!) {
        let graphic = callout.representedObject as! AGSGraphic
        //save a reference to the selected graphic, in order to pass it to the results view controller in prepareForSegue method
        self.selectedGraphic = graphic
        
        //perform the segue to transition to Results view controller
        self.performSegueWithIdentifier(kResultsViewSegueIdentifier, sender:self)
    }
    
    //MARK: - AGSLayerCalloutDelegate
    
    func callout(callout: AGSCallout!, willShowForFeature feature: AGSFeature!, layer: AGSLayer!, mapPoint: AGSPoint!) -> Bool {
        //If the result does not have any attributes, don't show the callout
        if feature.allAttributes() == nil || feature.allAttributes().count == 0 {
            return false
        }
        
        //The locator we are using in this sample returns 'Match_addr' attribute for geocoded results and
        //'Street' for reverse-geocoded results
        if feature.hasAttributeForKey("Match_addr") {
            callout.title = feature.attributeForKey("Match_addr") as! String
        }
        else if feature.hasAttributeForKey("Street") {
            callout.title = feature.attributeForKey("Street") as! String
        }
        
        //It also returns 'City' and 'ZIP' for both kind of results
        let zip = feature.attributeForKey("ZIP") as! String
        self.mapView.callout.detail = feature.attributeForKey("City").stringByAppendingString(", \(zip)")
        return true
    }
    
    //MARK: - AGSLocatorDelegate methods
    
    func locator(locator: AGSLocator!, operation op: NSOperation!, didFetchLocatorInfo locatorInfo: AGSLocatorInfo!) {
        print(locatorInfo.singleLineAddressField)
    }
    
    func locator(locator: AGSLocator!, operation op: NSOperation!, didFindLocationsForAddress candidates: [AnyObject]!) {
        //check and see if we didn't get any results
        if candidates == nil || candidates.count == 0 {
            
            //show alert if we didn't get results
            UIAlertView(title: "No Results", message:"No Results Found By Locator", delegate:nil, cancelButtonTitle:"OK").show()
        }
        else
        {
            //sort the results based on score
            let sortedCandidates = candidates.sort({ (a, b) -> Bool in
                let first = (a as! AGSAddressCandidate).score
                let second = (b as! AGSAddressCandidate).score
                return first > second
            })
            
            //loop through all candidates/results and add to graphics layer
            for candidate in sortedCandidates as! [AGSAddressCandidate] {
                let graphic = AGSGraphic(geometry: candidate.location, symbol:nil, attributes:candidate.attributes)
                
                //add the graphic to the graphics layer
                self.graphicsLayer.addGraphic(graphic)
                
                //if we have a 90% confidence in the first result.
                if candidate.score > 90 {
                    //show the callout for the one result we have
                    self.mapView.callout.showCalloutAtPoint(candidate.location, forFeature: graphic, layer: self.graphicsLayer, animated: true)
                    //don't process anymore results
                    break
                }
                
            }
            
            self.mapView.zoomToGeometry(self.graphicsLayer.fullEnvelope, withPadding:0, animated:true)
        }
    }
    
    func locator(locator: AGSLocator!, operation op: NSOperation!, didFailLocationsForAddress error: NSError!) {
        //The location operation failed display the error
        UIAlertView(title: "Locator Failed", message: error.description, delegate: nil, cancelButtonTitle: "OK").show()
    }
    
    func locator(locator: AGSLocator!, operation op: NSOperation!, didFindAddressForLocation candidate: AGSAddressCandidate!) {
        //display callout
        self.mapView.callout.showCalloutAt(candidate.location, screenOffset: self.magnifierOffset, animated: false)
        
        //show the Street, City, and ZIP attributes in the callout
        if let street:AnyObject = candidate.attributes["Street"] {
            self.mapView.callout.title = street as! String
        }
        if let zip:AnyObject = candidate.attributes["ZIP"] {
            if let city:AnyObject = candidate.attributes["City"] {
                self.mapView.callout.detail =  (city as! String).stringByAppendingString(", \(zip)")
            }
        }
        
        self.graphicsLayer.graphics.first?.setAttributes(candidate.attributes)
    }
    
    func locator(locator: AGSLocator!, operation op: NSOperation!, didFailAddressForLocation error: NSError!) {
        //dismiss the callout because we don't have an address to display
        self.mapView.callout.dismiss()
    }
    
    //MARK: - UISearchBarDelegate methods
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        //hide the callout
        self.mapView.callout.hidden = true
        
        //First hide the keyboard then start Geocoding
        self.view.endEditing(true)
        self.startGeocoding()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        //hide the keyboard
        self.view.endEditing(true)
    }
    
    func searchBarResultsListButtonClicked(searchBar: UISearchBar) {
        self.performSegueWithIdentifier(kRecentViewSegueIdentifier, sender: self)
    }
    
    //MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == kResultsViewSegueIdentifier {
            let controller = segue.destinationViewController as! ResultsViewController
            controller.results = self.selectedGraphic.allAttributes()
        }
        else if segue.identifier == kRecentViewSegueIdentifier {
            let controller = segue.destinationViewController as! RecentViewController
            controller.items = self.recentSearches
            controller.completion = { [weak self] (item) in
                if let weakSelf = self {
                    weakSelf.searchBar.text = item
                    weakSelf.dismissViewControllerAnimated(true, completion: nil)
                    weakSelf.searchBar.becomeFirstResponder()
                }
            }
        }
    }
}
