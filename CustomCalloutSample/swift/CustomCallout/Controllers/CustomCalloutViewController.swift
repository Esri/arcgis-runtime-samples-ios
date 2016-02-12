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

//base map url for the sample
let kBaseMap = "http://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer"
let kCustomHybridViewControllerIdentifier = "CustomHybridViewController"
let kCustomWebViewControllerIdentifier = "CustomWebViewController"

//this enum is used to determin the type of graphic created
enum GraphicType:Int {
    case EmbeddedMapView
    case EmbeddedWebView
    case CustomInfoView
    case SimpleView
}

class CustomCalloutViewController: UIViewController, AGSCalloutDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    var graphicsLayer:AGSGraphicsLayer!
    //this is the view controller that handles the loading and operations of the Bing Aerial view in a callout.
    var hybridViewController:CustomHybridViewController!
    //this is the view controller that handles the loading and operations of the Traffic Camera feed in a callout.
    var cameraViewController:CustomWebViewController!
    
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Add the basemap.
        let mapUrl = NSURL(string: kBaseMap)
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")

        //Zooming to an initial envelope with the specified spatial reference of the map.
        let sr = AGSSpatialReference(WKID: 102100)
        let env = AGSEnvelope(xmin: -9555813.309582941, ymin:4606200.425377472, xmax:-9543583.38505733, ymax:4623780.94188304, spatialReference:sr)
        self.mapView.zoomToEnvelope(env, animated:true)
        
        //set the callout delegate so we can display callouts
        self.mapView.callout.delegate = self
        
        //add  graphics layer for the graphics
        self.graphicsLayer = AGSGraphicsLayer()
        
        //add the sample graphics
        self.createSampleGraphics()
        
        //add the graphics layer to the map
        self.mapView.addMapLayer(self.graphicsLayer, withName:"SampleGraphics")
        
        //reference to the storyboard
        let storyboard = UIStoryboard(name: "Main", bundle:NSBundle.mainBundle())
        
        //initialize the hybrid map view with street map
        let frame = CGRect(x: 0, y: 0, width: 125, height: 125)
        self.hybridViewController = storyboard.instantiateViewControllerWithIdentifier(kCustomHybridViewControllerIdentifier) as! CustomHybridViewController
        self.hybridViewController.view.frame = frame
        self.hybridViewController.view.clipsToBounds = true
        
        //initialize the traffic camera view
        self.cameraViewController = storyboard.instantiateViewControllerWithIdentifier(kCustomWebViewControllerIdentifier) as! CustomWebViewController
        self.cameraViewController.view.frame = frame
        self.cameraViewController.view.clipsToBounds = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - AGSCalloutDelegate
    
    func callout(callout: AGSCallout!, willShowForFeature feature: AGSFeature!, layer: AGSLayer!, mapPoint: AGSPoint!) -> Bool {
        
        let graphic = feature as! AGSGraphic
        
        //extract the type of graphics to check.
        let typeNumber = graphic.attributeForKey("type") as! Int
        if let graphicType = GraphicType(rawValue: typeNumber) {
        
            switch graphicType {
                //graphic's callout is an embedded map view
            case .EmbeddedMapView:
                print("Tapped on Building")
                
                //call the helper method to update the hybrid map view according to the graphic
                self.hybridViewController.showHybridMapAtGraphic(graphic)
                
                //assign the hybrid map view to the callout view of the main map view
                self.mapView.callout.customView = self.hybridViewController.view
                
                return true
                
                //graphic's callout is an embedded map view
            case .EmbeddedWebView:
                print("Tapped on Camera")
                
                //get the url for the image feed from the camera
                if let imageURL = graphic.attributeAsStringForKey("url") {
                    
                    //create the url object
                    if let imageURLObject = NSURL(string: imageURL) {
                        //load the web view with the url. The web view will refresh the feed automatically every 2 seconds.
                        self.cameraViewController.loadUrlWithRepeatInterval(imageURLObject, withRepeatInterval:10)
                        
                        //assign the camera view as the custom view of the callout for this graphic.
                        self.mapView.callout.customView = self.cameraViewController.view
                        
                        return true
                    }
                }

                //graphic's callout is a view with title, detail, custom accessory button and an image.
            case .CustomInfoView:
                print("Tapped on McDonalds")
                
                //clear the custom view.
                self.mapView.callout.customView = nil
                
                //get the attribute values for the graphic
                self.mapView.callout.title = graphic.attributeAsStringForKey("name")
                self.mapView.callout.detail = graphic.attributeAsStringForKey("address")
                
                //sets the left image of the callout.
                self.mapView.callout.image = UIImage(named: "McDonalds.png")
                
                //creates the custom button image for the accessory view of the callout
                self.mapView.callout.accessoryButtonType = .Custom
                self.mapView.callout.accessoryButtonImage = UIImage(named: "Phone.png")
                self.mapView.callout.accessoryButtonHidden = false
                
                return true

                //graphic's callout is a simple view with just the title and detail
            case .SimpleView:
                print("Tapped on Monument")
                
                //clear the custom view.
                self.mapView.callout.customView = nil
                
                //get the attribute values for the graphic
                self.mapView.callout.title = graphic.attributeAsStringForKey("name")
                self.mapView.callout.detail = graphic.attributeAsStringForKey("address")
                
                //hide the accessory view and also the left image view.
                self.mapView.callout.accessoryButtonHidden = true
                self.mapView.callout.image = nil
                
                return true
            }
        }
    
        
        return false
    }
    
    func didClickAccessoryButtonForCallout(callout: AGSCallout!) {
        let graphic = callout.representedFeature as! AGSGraphic
        //extract the type of graphics to check.
        var exists = ObjCBool(false)
        let typeNumber = graphic.attributeAsIntegerForKey("type", exists: &exists)
        if (exists) {
            if let graphicType = GraphicType(rawValue: typeNumber)
            {
                switch graphicType {
                    //only this graphic's callout has an accessory view.
                case .CustomInfoView:
                    print("Tapped accessory button on McDonalds callout")
                    
                    //get the phone number and create the proper string.
                    if let phoneString = graphic.attributeAsStringForKey("phone") {
                        let phoneNumber = "tel://\(phoneString)"
                        //call the number.
                        UIApplication.sharedApplication().openURL(NSURL(string: phoneNumber)!)
                    }
            
                default:
                    break
                }
            }
        }
    }
    
    //MARK: - Helper Methods
    
    //creating sample graphics.
    func createSampleGraphics() {
        var graphic:AGSGraphic!
        var graphicPoint:AGSPoint!
        var graphicAttributes = [NSObject:AnyObject]()
        var graphicSymbol:AGSPictureMarkerSymbol!
        
        //Graphic for demonstrating Bing's aerial view
        graphicPoint = AGSPoint(x: -9546541.78950715, y:4615710.12174574, spatialReference:self.mapView.spatialReference)
        graphicAttributes = ["type": GraphicType.EmbeddedMapView.rawValue]
        graphicSymbol = AGSPictureMarkerSymbol(imageNamed: "Building.png")
        graphic = AGSGraphic(geometry: graphicPoint, symbol:graphicSymbol, attributes:graphicAttributes)
        self.graphicsLayer.addGraphic(graphic)
        
        //Graphic for demonstrating embedded Web view (traffic camera feed)
        graphicPoint = AGSPoint(x: -9552294.6205, y:4618447.7069, spatialReference:self.mapView.spatialReference)
        graphicAttributes = ["type": GraphicType.EmbeddedWebView.rawValue, "url":"http://www.trimarc.org/images/snapshots/CCTV060.jpg"]
        graphicSymbol = AGSPictureMarkerSymbol(imageNamed: "TrafficCamera.png")
        graphic = AGSGraphic(geometry: graphicPoint, symbol:graphicSymbol, attributes:graphicAttributes)
        self.graphicsLayer.addGraphic(graphic)
        
        //Graphic for demonstrating custom callout with buttons
        graphicPoint = AGSPoint(x: -9550988.22392791, y:4614761.34217867, spatialReference:self.mapView.spatialReference)
        graphicAttributes = ["type": GraphicType.CustomInfoView.rawValue, "name":"McDonalds", "address":"2720 West Broadway, Louisville, KY 40211-1320", "phone":"5027787110", "url":"www.mcdonals.com"]
        graphicSymbol = AGSPictureMarkerSymbol(imageNamed: "McDonalds.png")
        graphic = AGSGraphic(geometry: graphicPoint, symbol:graphicSymbol, attributes:graphicAttributes)
        self.graphicsLayer.addGraphic(graphic)
        
        //Graphic for demonstrating simple callout
        graphicPoint = AGSPoint(x: -9547261.91529309, y:4615891.15535562, spatialReference:self.mapView.spatialReference)
        graphicAttributes = ["type": GraphicType.SimpleView.rawValue, "name":"Frazier Museum", "address":"829 West Main Street, Louisville, KY 40202"]
        graphicSymbol = AGSPictureMarkerSymbol(imageNamed: "Museum.png")
        graphic = AGSGraphic(geometry: graphicPoint, symbol:graphicSymbol, attributes:graphicAttributes)
        self.graphicsLayer.addGraphic(graphic)
    }
}
