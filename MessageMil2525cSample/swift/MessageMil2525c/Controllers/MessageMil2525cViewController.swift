//
// Copyright 2015 ESRI
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

//contants for data layers
let kTiledMapServiceURL = "http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer"

class Mil2525Message: NSObject, AGSCoding {
    var message:AGSMPMessage!
    
    required init!(JSON json: [NSObject : AnyObject]!) {
        super.init()
        self.decodeWithJSON(json)
    }
    
    func decodeWithJSON(json: [NSObject : AnyObject]!) {
        self.message = AGSMPMessage()
        
        for (key, value) in json {
            self.message.setProperty(value, forKey: key as! NSString as String)
        }
    }
}

class MessageMil2525cViewController: UIViewController, AGSMapViewLayerDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    var groupLayer:AGSGroupLayer!
    var message:AGSMPMessage!
    var mProcessor:AGSMPMessageProcessor!
    var milMessages:[Mil2525Message]!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Set the delegate for the map view
        self.mapView.layerDelegate = self
        
        //Create an instance of a tiled map service layer
        let tiledLayer = AGSTiledMapServiceLayer(URL: NSURL(string: kTiledMapServiceURL))
        
        //Add it to the map view
        self.mapView.addMapLayer(tiledLayer, withName:"Tiled Layer")
        
        let sr = AGSSpatialReference(WKID: 4326)
        
        //Create envelope defining location of message file
        let env = AGSEnvelope(xmin: -2.13, ymin:51.24, xmax:-1.93, ymax:51.44, spatialReference:sr)
        
        self.mapView.zoomToEnvelope(env, animated:true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - AGSMapViewLayerDelegate methods
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        
        //Create a Group Layer
        self.groupLayer = AGSGroupLayer()
        
        //Add the Group Layer to the MapView
        self.mapView.addMapLayer(self.groupLayer, withName:"Message Processing Group Layer")
        
        //Create a message processor
        //Pass the symbol dictionary type and the group layer in the Constructor
        
        self.mProcessor = AGSMPMessageProcessor(symbolDictionaryType: AGSMPSymbolDictionaryType.Mil2525C, groupLayer: self.groupLayer)
        
        //Create the file path to the military message json file
        let filePath = NSBundle.mainBundle().pathForResource("Mil2525CMessages", ofType:"json", inDirectory:nil)
        
        //Create a JSON Parser
        let parser = AGSSBJsonParser()
        
        //Store the contents of the JSON file in a string
        let jsonString = try! String(contentsOfFile: filePath!, encoding: NSUTF8StringEncoding)
        
        //Store the JSON string in a dictionary
        let json = parser.objectWithString(jsonString) as! [NSObject:AnyObject]
        
        //Decode the JSON in the dictionary
        self.milMessages = AGSJSONUtility.decodeFromDictionary(json, withKey: "messages", fromClass: Mil2525Message.self) as AnyObject as! [Mil2525Message]
        
        //Process every message in the decoded JSON
        for message in self.milMessages {
            self.mProcessor.processMessage(message.message)
        }
    
    }
}
