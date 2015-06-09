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

//this is the url for the basemap.
let kBaseMapServiceURL = "http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"

//url for the incidents layer
let kIncidentsLayerURL = "http://sampleserver3.arcgisonline.com/ArcGIS/rest/services/SanFrancisco/311Incidents/FeatureServer/0"

class RelatedRecordEditingViewController: UIViewController, AGSCalloutDelegate, AGSPopupsContainerDelegate, NotesViewControllerDelegate {
    
    @IBOutlet weak var mapView:AGSMapView!
    var incidentsLayer:AGSFeatureLayer!
    var popupVC:AGSPopupsContainerViewController!
    var customActionButton:UIBarButtonItem!
    var loadingView:LoadingView!
    
    var selectedIncidentsOID:Int!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //creating a tiled service with the base map url
        let mapUrl = NSURL(string: kBaseMapServiceURL)
        let tiledLyr = AGSTiledMapServiceLayer(URL: mapUrl)
        
        //add the tiled layer to the map view
        self.mapView.addMapLayer(tiledLyr, withName:"Tiled Layer")
        
        //Zooming to an initial envelope with the specified spatial reference of the map.
        //this is the San Francisco extent.
        let sr = AGSSpatialReference(WKID: 102100)
        let env = AGSEnvelope(xmin: -13639984, ymin:4537387, xmax:-13606734, ymax:4558866, spatialReference:sr)
        self.mapView.zoomToEnvelope(env, animated:true)
        
        //Set up the map view
        self.mapView.callout.delegate = self
        
        //setup the incidents layer as a feature layer and add it to the map
        self.incidentsLayer = AGSFeatureLayer(URL: NSURL(string: kIncidentsLayerURL), mode:.OnDemand)
        self.incidentsLayer.outFields = ["*"]
        self.incidentsLayer.calloutDelegate = self.incidentsLayer
        
        self.mapView.addMapLayer(self.incidentsLayer, withName:"Incidents")
        
        //setting the custom action button which will be later used to display related notes of an incident
        self.customActionButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Compose, target: self, action: "displayIncidentNotes")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSCalloutDelegate methods
    
    func didClickAccessoryButtonForCallout(callout: AGSCallout!) {
        
        let graphic = callout.representedObject as! AGSGraphic
        self.incidentsLayer = graphic.layer as! AGSFeatureLayer
        
        //Show popup for the graphic because the user tapped on the callout accessory button
        //this is a client side popup based on the graphic that was selected.
        let info = AGSPopupInfo(forGraphic: graphic)
        self.popupVC = AGSPopupsContainerViewController(popupInfo: info, graphic:graphic, usingNavigationControllerStack:false)
        self.popupVC.delegate = self
        self.popupVC.actionButton = self.customActionButton //set the custom action button.
        self.popupVC.modalTransitionStyle =  .FlipHorizontal
        
        //If iPad, use a modal presentation style
        if AGSDevice.currentDevice().isIPad() {
            self.popupVC.modalPresentationStyle = .FormSheet
        }
        self.presentViewController(self.popupVC, animated:true, completion:nil)
    }
    
    
    
    //MARK: -  AGSPopupsContainerDelegate methods
    
    func popupsContainerDidFinishViewingPopups(popupsContainer: AGSPopupsContainer!) {
        //dismiss the popups view controller
        self.dismissViewControllerAnimated(true, completion:nil)
        self.popupVC = nil
    }
    
    //MARK: - Helper
    
    func warnUserOfErrorWithMessage(message:String) {
        //Display an alert to the user
        UIAlertView(title: "Error", message: message, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    func displayIncidentNotes() {
        //get the current popup.
        let currentPopup = self.popupVC.currentPopup
        
        //obtain the OID of the current popup graphic
        let incidentOID = currentPopup.graphic.attributeAsIntegerForKey("objectid", exists:nil)
            
        //show the related notes
        self.selectedIncidentsOID = incidentOID
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let notesVC = storyboard.instantiateViewControllerWithIdentifier("NotesViewController") as! NotesViewController
        notesVC.delegate = self
        notesVC.incidentOID = incidentOID
        notesVC.incidentLayer = self.incidentsLayer
        self.popupVC.presentViewController(notesVC, animated: true, completion: nil)
    }
    
    //MARK: - NotesViewControllerDelegate
    
    func didFinishWithNotes() {
        //dismiss the notes view.
        self.popupVC.dismissViewControllerAnimated(true, completion:nil)
    }
}
