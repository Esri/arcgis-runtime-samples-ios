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

//base map rest url
let kBaseMapURL = "http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"
let kSettingsSegueIdentifier = "SettingsViewSegue"
let kAccuracyValueKeyPath = "self.parameters.accuracyValue"
let kFrequencyValueKeyPath = "self.parameters.frequencyValue"

class GpsSketchingViewController: UIViewController, AGSMapViewLayerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var startStopButton:UIBarButtonItem!
    @IBOutlet weak var addCurrentLocButton:UIBarButtonItem!
    
    var gpsSketchLayer:AGSSketchGraphicsLayer!
    var locationManager:CLLocationManager!
    var parameters:Parameters!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //initialize the map URL and the tiled map layer.
        let mapUrl = NSURL(string: kBaseMapURL)
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        
        //Add the tiled map layer to the map view.
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        //set the layer delegate to self to check when the layers are loaded. Required to start the gps.
        self.mapView.layerDelegate = self
        
        //preparing the gps sketch layer.
        self.gpsSketchLayer = AGSSketchGraphicsLayer(geometry: nil)
        self.mapView.addMapLayer(self.gpsSketchLayer, withName:"Sketch layer")
        
        //this button is enabled only when the trackin has started.
        self.addCurrentLocButton.enabled = false
        
        self.startStopButton.enabled = false
        
        //instantiate the parameters object
        self.parameters = Parameters()
        
        //observe for changes in the parameters/settings
        self.addObserver(self, forKeyPath:kAccuracyValueKeyPath, options:.New, context:nil)
        self.addObserver(self, forKeyPath:kFrequencyValueKeyPath, options:.New, context:nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: -
    
    //update the location manager parameters if the settings are changed during sketching
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if keyPath == kAccuracyValueKeyPath {
            self.locationManager.desiredAccuracy = self.parameters.accuracyValue
        }
        else if keyPath == kFrequencyValueKeyPath {
            self.locationManager.distanceFilter = self.parameters.frequencyValue
        }
    }
    
    //MARK: - AGSMapViewLayerDelegate methods
    
    func mapViewDidLoad(mapView: AGSMapView!) {
        
        self.mapView.locationDisplay.startDataSource()
        self.mapView.locationDisplay.autoPanMode = .Default
        
        self.startStopButton.enabled = true
        
        //setting the geometry of the gps sketch layer to polyline.
        self.gpsSketchLayer.geometry = AGSMutablePolyline(spatialReference: self.mapView.spatialReference)
        
        //set the midvertex symbol to nil to avoid the default circle symbol appearing in between vertices
        self.gpsSketchLayer.midVertexSymbol = nil
    }
    
    //MARK: - Action methods
    
    @IBAction func showCurrentLocation() {
        self.mapView.centerAtPoint(self.mapView.locationDisplay.mapLocation(), animated:true)
        self.mapView.locationDisplay.autoPanMode = .Default
    }
    
    @IBAction func addCurrentLocationAsVertex() {
        //add the present gps point to the sketch layer. Notice that we do not have to reproject this point as the mapview's gps object is returing the point in the same spatial reference.
        //index -1 causes vertex to be added at the end
        self.gpsSketchLayer.insertVertex(self.mapView.locationDisplay.mapLocation(), inPart:0, atIndex:-1)
    }
    
    @IBAction func startGPSSketching(sender:AnyObject) {
        //we remove the previos part from the sketch layer as we are going to start a new GPS path.
        self.gpsSketchLayer.removePartAtIndex(0)
        
        //add a new path to the geometry in preparation of adding vertices to the path
        self.gpsSketchLayer.addPart()
        
        //create the location manager.
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        
        //set the preferences that was configured using the settings view.
        self.locationManager.desiredAccuracy = self.parameters.accuracyValue
        self.locationManager.distanceFilter = self.parameters.frequencyValue
            
        //start the location maneger.
        self.locationManager.startUpdatingLocation()
        
        //set the title of the button to Stop and change the selector on it.
        self.startStopButton.title = "Stop"
        self.startStopButton.action = "stopGPSSketching"
        
        //by enabling this, the user can now add their prest location as a vertex to the path.
        self.addCurrentLocButton.enabled = true
    }
    
    @IBAction func stopGPSSketching() {
        
        //stop the CLLocation manager from sending updates.
        self.locationManager.stopUpdatingLocation()
        
        //change the button title back to Start
        self.startStopButton.title = "Start"
        
        //disable the button for adding current location as vertex.
        self.addCurrentLocButton.enabled = false
        
        //change the selector on the start stop button back to "startGPSSketching"
        self.startStopButton.action = "startGPSSketching:"
    }
    
    
    //MARK: - Location Manager Interactions
    
    /*
    * We want to get and store a location measurement that meets the desired accuracy. For this example, we are
    *      going to use horizontal accuracy as the deciding factor. In other cases, you may wish to use vertical
    *      accuracy, or both together.
    */
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        
        // test that the horizontal accuracy does not indicate an invalid measurement
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        //add the present gps point to the sketch layer. Notice that we do not have to reproject this point as the mapview's gps object is returing the point in the same spatial reference.
        //index -1 forces the vertex to be added at the end
        self.gpsSketchLayer.insertVertex(self.mapView.locationDisplay.mapLocation(), inPart:0, atIndex:-1)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {

        // The location "unknown" error simply means the manager is currently unable to get the location.
        if error.code != CLError.LocationUnknown.rawValue {
            self.stopUpdatingLocation()
        }
    }
    
    func stopUpdatingLocation() {
        //stop the location manager and set the delegate to nil;
        self.locationManager.stopUpdatingLocation()
        self.locationManager.delegate = nil
    }
    
    //MARK: -
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == kSettingsSegueIdentifier {
            let controller = segue.destinationViewController as! SettingsViewController
            controller.parameters = self.parameters
            
            if AGSDevice.currentDevice().isIPad() {
                controller.modalPresentationStyle = .FormSheet
                
                //present settings view
                controller.modalTransitionStyle = .CoverVertical
//                controller.view.superview.bounds = CGRectMake(0, 0, 400, 300)
            }
        }
    }
}
