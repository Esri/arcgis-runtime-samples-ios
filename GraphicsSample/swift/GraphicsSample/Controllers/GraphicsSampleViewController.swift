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

let kFeatureDetailControllerIdentifier = "FeatureDetailViewController"

class GraphicsSampleViewController: UIViewController, AGSMapViewLayerDelegate, AGSCalloutDelegate, AGSQueryTaskDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    
    var countyGraphicsLayer:AGSGraphicsLayer!
    var countyQueryTask:AGSQueryTask!
    var countyInfoTemplate:CountyInfoTemplate!
    var cityGraphicsLayer:AGSGraphicsLayer!
    var cityQueryTask:AGSQueryTask!

    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.mapView.layerDelegate = self
        self.mapView.callout.delegate = self
        
        //create an instance of a tiled map service layer
        //Add it to the map view
        let serviceUrl = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer")
        let tiledMapServiceLayer = AGSTiledMapServiceLayer(URL: serviceUrl)
        self.mapView.addMapLayer(tiledMapServiceLayer, withName:"World Street Map")
        
        //COUNTY
        //add county graphics layer (data is loaded in mapViewDidLoad method)
        self.countyGraphicsLayer = AGSGraphicsLayer()
        self.mapView.addMapLayer(self.countyGraphicsLayer, withName:"States Graphics Layer")
        
        //callouts are only availabl efor counties layer in this sample
        //create an instance of the callout template
        self.countyInfoTemplate = CountyInfoTemplate()
        self.countyGraphicsLayer.calloutDelegate = self.countyInfoTemplate
        
        //CITY
        self.cityGraphicsLayer = AGSGraphicsLayer()
        
        //renderer for cities
        let cityRenderer = AGSUniqueValueRenderer()
        cityRenderer.defaultSymbol = AGSSimpleMarkerSymbol()
        cityRenderer.fields = ["TYPE"]
        
        //census designated place, city, town
        //create marker symbols for census, cities and towns and apply to renderer
        let censusMarkeySymbol = AGSSimpleMarkerSymbol()
        censusMarkeySymbol.color = UIColor.yellowColor()
        
        let cityMarkerSymbol = AGSSimpleMarkerSymbol()
        cityMarkerSymbol.style = .Diamond
        cityMarkerSymbol.outline.color = UIColor.blueColor()
        
        let townMarkerSymbol = AGSSimpleMarkerSymbol()
        townMarkerSymbol.style = .Cross
        townMarkerSymbol.outline.width = 3.0
        
        cityRenderer.uniqueValues = [
        AGSUniqueValue(value: "census designated place", label: "census designated place", description: "census designated place", symbol: censusMarkeySymbol),
        AGSUniqueValue(value: "city", label: "city", description: "city", symbol: cityMarkerSymbol),
        AGSUniqueValue(value: "town", label: "town", description: "town", symbol: townMarkerSymbol)]
        
        //apply city renderer
        self.cityGraphicsLayer.renderer = cityRenderer
        
        //add cities graphics layer (data is loaded in mapViewDidLoad method)
        self.mapView.addMapLayer(self.cityGraphicsLayer, withName:"City Graphics Layer")
        
        self.cityGraphicsLayer.visible = false
        self.countyGraphicsLayer.visible = true
        
        
        //Zoom To Envelope
        //create extent to be used as default
        let envelope = AGSEnvelope(xmin: -124.83145667, ymin:30.49849464, xmax:-113.91375495, ymax:44.69150688, spatialReference:AGSSpatialReference(WKID: 4326))
        
        //call method to set extent, pass in envelope
        self.mapView.zoomToEnvelope(envelope, animated:true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func toggleGraphicsLayer(sender:UISegmentedControl) {
    
        //toggles between Cities and Counties graphics layer
        
        if sender.selectedSegmentIndex == 0 {
            self.cityGraphicsLayer.visible = false
            self.countyGraphicsLayer.visible = true
            self.mapView.callout.hidden = false
        }
        else {
            self.cityGraphicsLayer.visible = true
            self.countyGraphicsLayer.visible = false
            self.mapView.callout.hidden = true
        }
    }
    
    
    //MARK: - AGSMapViewLayerDelegate
    
    //called when the map view is loaded (after the view is loaded)
    func mapViewDidLoad(mapView: AGSMapView!) {
        
        self.mapView.callout.width = 235.0
        
        //set up query task for counties and perform query returning all atrributes
        self.countyQueryTask = AGSQueryTask(URL: NSURL(string: "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StateCityHighway_USA/MapServer/2"))
        self.countyQueryTask.delegate = self
        
        let countyQuery = AGSQuery()
        countyQuery.whereClause = "STATE_NAME = 'California'"
        countyQuery.outFields = ["*"]
        countyQuery.returnGeometry = true
        countyQuery.outSpatialReference = self.mapView.spatialReference
        self.countyQueryTask.executeWithQuery(countyQuery)
        
        //set up query task for cities and perform query returning all atrributes
        self.cityQueryTask = AGSQueryTask(URL: NSURL(string: "http://sampleserver1.arcgisonline.com/ArcGIS/rest/services/Specialty/ESRI_StatesCitiesRivers_USA/MapServer/0"))
        self.cityQueryTask.delegate = self
        
        let cityQuery = AGSQuery()
        cityQuery.whereClause = "STATE_NAME = 'California'"
        cityQuery.outFields = ["*"]
        cityQuery.returnGeometry = true
        cityQuery.outSpatialReference = self.mapView.spatialReference
        self.cityQueryTask.executeWithQuery(cityQuery)
    }
    
    //MARK: - AGSCalloutDelegate
    
    //when a user clicks the detail disclosure button on the call out
    func didClickAccessoryButtonForCallout(callout: AGSCallout!) {
        //instantiate an object of the FeatureDetailsViewController
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let featureDetailsViewController = storyboard.instantiateViewControllerWithIdentifier(kFeatureDetailControllerIdentifier) as! FeatureDetailsViewController
        
        //assign the feature to be presented in the details view
        featureDetailsViewController.feature = callout.representedObject as! AGSGraphic
        featureDetailsViewController.displayFieldName = "NAME"
        
        //in case of an iPad present as a form sheet
        if AGSDevice.currentDevice().isIPad() {
            featureDetailsViewController.modalPresentationStyle = .FormSheet
        }
        
        self.navigationController?.presentViewController(featureDetailsViewController, animated: true, completion: nil)
    }
    
    //MARK:- AGSQueryTaskDelegate
    
    //when query is executed ....
    func queryTask(queryTask: AGSQueryTask!, operation op: NSOperation!, didExecuteWithFeatureSetResult featureSet: AGSFeatureSet!) {
        
        //create extent to be used as default
        let envelope = AGSEnvelope(xmin:-124.83145667, ymin:30.49849464, xmax:-113.91375495, ymax:44.69150688, spatialReference:AGSSpatialReference(WKID: 4326))
        
        //call method to set extent, pass in envelope
        self.mapView.zoomToEnvelope(envelope, animated:true)
        
        //determine if it's a query on counties or cities then assign to applicable layer
        if featureSet.displayFieldName == "CITY_NAME" {
            for graphic in featureSet.features as! [AGSGraphic] {
                self.cityGraphicsLayer.addGraphic(graphic)
            }
            
            self.cityQueryTask = nil
        }
        else {
            let fillSymbol = AGSSimpleFillSymbol()
            fillSymbol.color = UIColor.blackColor().colorWithAlphaComponent(0.25)
            fillSymbol.outline.color = UIColor.darkGrayColor()
            
            //display counties on graphics layer and specify callout template
            for graphic in featureSet.features as! [AGSGraphic] {
                graphic.symbol = fillSymbol
                self.countyGraphicsLayer.addGraphic(graphic)
            }
            
            self.countyQueryTask = nil;
        }
    }
    
    //if there's an error with the query task give info to user
    func queryTask(queryTask: AGSQueryTask!, operation op: NSOperation!, didFailWithError error: NSError!) {
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }

}
