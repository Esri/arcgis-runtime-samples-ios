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

//constants for title, search bar placeholder text and data layer
let kViewTitle = "US State/City/River"
let kSearchBarPlaceholder = "Find State/City/River"
let kDynamicMapServiceURL = "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer"
let kTiledMapServiceURL = "http://services.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"
let kResultsSegueIdentifier = "ResultsSegue"

class FindTaskViewController: UIViewController, AGSMapViewLayerDelegate, AGSCalloutDelegate, AGSLayerCalloutDelegate, AGSFindTaskDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var searchBar:UISearchBar!
    var dynamicLayer:AGSDynamicMapServiceLayer!
    var dynamicLayerView:UIView!
    var graphicsLayer:AGSGraphicsLayer!
    var findTask:AGSFindTask!
    var findParams:AGSFindParameters!
    var cityCalloutTemplate:AGSCalloutTemplate!
    var riverCalloutTemplate:AGSCalloutTemplate!
    var stateCalloutTemplate:AGSCalloutTemplate!
    var selectedGraphic:AGSGraphic!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //title for the navigation controller
        self.title = kViewTitle
        
        //text in search bar before user enters in query
        self.searchBar.placeholder = kSearchBarPlaceholder
        
        //set map view delegate
        self.mapView.layerDelegate = self
        self.mapView.callout.delegate = self
        
        //create and add a base layer to map
        let tiledMapServiceLayer = AGSTiledMapServiceLayer(URL: NSURL(string: kTiledMapServiceURL))
        self.mapView.addMapLayer(tiledMapServiceLayer, withName:"World Street Map")
        
        //create and add dynamic layer to map
        self.dynamicLayer = AGSDynamicMapServiceLayer(URL: NSURL(string: kDynamicMapServiceURL))
        self.mapView.addMapLayer(self.dynamicLayer, withName:"Dynamic Layer")
        
        //create and add graphics layer to map
        self.graphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.graphicsLayer, withName:"Graphics Layer")
        //set the callout delegate so that we can show an appropriate callout for graphics
        self.graphicsLayer.calloutDelegate = self
        
        //create find task and set the delegate
        self.findTask = AGSFindTask(URL: NSURL(string: kDynamicMapServiceURL))
        self.findTask.delegate = self
        
        //create find task parameters
        self.findParams = AGSFindParameters()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //MARK: -
    //MARK: AGSMapViewLayerDelegate
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        
        let spatialReference = AGSSpatialReference.wgs84SpatialReference()
        //zoom to dynamic layer
        let envelope = AGSEnvelope(xmin: -178.217598362366, ymin:18.9247817993164, xmax:-66.9692710360024, ymax:71.4062353532712, spatialReference:spatialReference)
        
        let geometryEngine = AGSGeometryEngine()
        let webMercatorEnvelope = geometryEngine.projectGeometry(envelope, toSpatialReference: self.mapView.spatialReference) as! AGSEnvelope
        
        self.mapView.zoomToEnvelope(webMercatorEnvelope, animated:true)
    }
    
    //MARK: -
    //MARK: AGSCalloutDelegate
    
    func didClickAccessoryButtonForCallout(callout: AGSCallout!) {
        //save selected graphic to assign it to the results view controller
        self.selectedGraphic = callout.representedObject as! AGSGraphic
        
        self.performSegueWithIdentifier(kResultsSegueIdentifier, sender:self)
    }
    
    //MARK: - UISearchBarDelegate
    
    //when the user searches
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        //hide the callout
        self.mapView.callout.hidden = true
        
        //set find task parameters
        self.findParams.contains = true
        self.findParams.layerIds = ["2","1","0"]
        self.findParams.outSpatialReference = self.mapView.spatialReference
        self.findParams.returnGeometry = true
        self.findParams.searchFields = ["CITY_NAME","NAME","STATE_ABBR","STATE_NAME"]
        self.findParams.searchText = searchBar.text
        
        //execute find task
        self.findTask.executeWithParameters(self.findParams)
        
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    //MARK: - AGSFindTaskDelegate
    
    func findTask(findTask: AGSFindTask!, operation op: NSOperation!, didExecuteWithFindResults results: [AnyObject]!) {
        
        //clear previous results
        self.graphicsLayer.removeAllGraphics()
        
        //use these to calculate extent of results
        var xmin = DBL_MAX
        var ymin = DBL_MAX
        var xmax = -DBL_MAX
        var ymax = -DBL_MAX
        
        //result object
        var result:AGSFindResult!
        
        //loop through all results
        for (var i=0 ; i < results.count ; i++) {
            
            //set the result object
            result = results[i] as! AGSFindResult
            
            //accumulate the min/max
            if (result.feature.geometry.envelope.xmin < xmin) {
                xmin = result.feature.geometry.envelope.xmin
            }
            
            if (result.feature.geometry.envelope.xmax > xmax) {
                xmax = result.feature.geometry.envelope.xmax
            }
            
            if (result.feature.geometry.envelope.ymin < ymin) {
                ymin = result.feature.geometry.envelope.ymin
            }
            
            if (result.feature.geometry.envelope.ymax > ymax) {
                ymax = result.feature.geometry.envelope.ymax
            }
            
            //if result feature geometry is point/polyline/polygon
            if (result.feature.geometry is AGSPoint) {
                //create and set marker symbol
                let symbol = AGSSimpleMarkerSymbol()
                symbol.color = UIColor.yellowColor()
                symbol.style = .Diamond
                result.feature.symbol = symbol
            }
            else if (result.feature.geometry is AGSPolyline) {
                
                //create and set simple line symbol
                let symbol = AGSSimpleLineSymbol()
                symbol.style = .Solid
                symbol.color = UIColor.blueColor()
                symbol.width = 2
                result.feature.symbol = symbol
            }
            else if (result.feature.geometry is AGSPolygon) {
                
                //create and set simple line symbol
                let outline = AGSSimpleLineSymbol()
                outline.style = .Solid
                outline.color = UIColor.redColor()
                outline.width = 2
                
                let symbol = AGSSimpleFillSymbol()
                symbol.outline = outline
                
                result.feature.symbol = symbol
            }
            
            //add graphic to graphics layer
            self.graphicsLayer.addGraphic(result.feature)
        }
        
        if results.count == 1 {
            //we have one result, center at that point
            self.mapView.centerAtPoint(result.feature.geometry.envelope.center, animated:false)
            
            //show the callout
            self.mapView.callout.showCalloutAtPoint(result.feature.geometry.envelope.center, forFeature:result.feature, layer:result.feature.layer, animated:true)
        }
        
        //if we have more than one result, zoom to the extent of all results
        if results.count > 1 {
            let extent = AGSMutableEnvelope(xmin: xmin, ymin:ymin, xmax:xmax, ymax:ymax, spatialReference:self.mapView.spatialReference)
            extent.expandByFactor(1.5)
            self.mapView.zoomToEnvelope(extent, animated:true)
        }
    }
    
    //if there's an error with the find display it to the user
    func findTask(findTask: AGSFindTask!, operation op: NSOperation!, didFailWithError error: NSError!) {
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    //MARK: - AGSLayerCalloutDelegate
    func callout(callout: AGSCallout!, willShowForFeature feature: AGSFeature!, layer: AGSLayer!, mapPoint: AGSPoint!) -> Bool {
        //set callout width
        self.mapView.callout.width = 200
        self.mapView.callout.detail = "Click for more detail.."
        
        if feature.hasAttributeForKey("CITY_NAME") {
            self.mapView.callout.title = feature.attributeAsStringForKey("CITY_NAME")
        }
        else if feature.hasAttributeForKey("NAME") {
            self.mapView.callout.title = feature.attributeAsStringForKey("NAME")
        }
        else if feature.hasAttributeForKey("STATE_NAME") {
            self.mapView.callout.title = feature.attributeAsStringForKey("STATE_NAME")
        }
        return true
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kResultsSegueIdentifier {
            let controller = segue.destinationViewController as! ResultsViewController
            controller.results = self.selectedGraphic.allAttributes()
        }
    }
}
