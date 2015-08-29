// Copyright 2015 Esri.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class EditFeaturesOnlineViewController: UIViewController, AGSMapViewTouchDelegate, AGSPopupsContainerDelegate, FeatureTemplatePickerDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var sketchToolbar:UIToolbar!
    @IBOutlet private weak var doneBBI:UIBarButtonItem!
    
    private var map:AGSMap!
    private var featureLayer:AGSFeatureLayer!
    private var popupsContainerVC:AGSPopupsContainerViewController!
    private var sketchGraphicsOverlay:AGSSketchGraphicsOverlay!
    
    private var lastQuery:AGSCancellable!
    private var newFeature:AGSArcGISFeature!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditFeaturesOnlineViewController","FeatureTemplatePickerViewController"]
        
        self.sketchGraphicsOverlay = AGSSketchGraphicsOverlay()
        self.mapView.graphicsOverlays.addObject(self.sketchGraphicsOverlay)
        
        self.map = AGSMap(basemap: AGSBasemap.topographicBasemap())
        //set initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -9184518.55, y: 3240636.90, spatialReference: AGSSpatialReference.webMercator()), scale: 7e5)
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
        let featureTable = AGSServiceFeatureTable(URL: NSURL(string: "http://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0"))
        featureTable.outFields = ["*"]
        self.featureLayer = AGSFeatureLayer(featureTable: featureTable)
        self.map.operationalLayers.addObject(featureLayer)
                
        //hide the sketchToolbar initially
        self.sketchToolbar.hidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func dismissFeatureTemplatePickerVC() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func applyEdits() {
        (self.featureLayer.featureTable as! AGSServiceFeatureTable).applyEditsWithCompletion { [weak self] (result:[AnyObject]!, error:NSError!) -> Void in
            if let error = error {
                SVProgressHUD.showErrorWithStatus("Error while applying edits :: \(error.localizedDescription)")
            }
            else {
                SVProgressHUD.showSuccessWithStatus("Edits applied successfully!")
            }
        }
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView!, didTapAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!) {
        if let lastQuery = self.lastQuery{
            lastQuery.cancel()
        }
        
        var tolerance:Double = 22
        var mapTolerance = tolerance * self.mapView.unitsPerPixel
        var envelope = AGSEnvelope(XMin: mappoint.x - mapTolerance, yMin: mappoint.y - mapTolerance, xMax: mappoint.x + mapTolerance, yMax: mappoint.y + mapTolerance, spatialReference: self.map.spatialReference)
        var queryParams = AGSQueryParameters()
        queryParams.geometry = envelope
        queryParams.outFields = ["*"]
        

        self.lastQuery = self.featureLayer.featureTable.queryFeaturesWithParameters(queryParams){ [weak self] (queryResult, error) in
            if let error = error {
                println(error)
            }
            if let result = queryResult,
                enumerator = result.enumerator(), weakSelf = self {
                    var popups = [AGSPopup]()
                    
                    while let f = enumerator.nextObject() as? AGSArcGISFeature{

                        var popup = AGSPopup(geoElement: f)
                        popups.append(popup)
                    }
                    
                    if popups.count > 0 {
                        weakSelf.popupsContainerVC = AGSPopupsContainerViewController(popups: popups, usingNavigationControllerStack: false)
                        weakSelf.popupsContainerVC.modalPresentationStyle = .FormSheet
                        weakSelf.presentViewController(weakSelf.popupsContainerVC, animated: true, completion: nil)
                        weakSelf.popupsContainerVC?.delegate = weakSelf
                    }
            }
            else if let error = error{
                println("error querying feature layer: \(error)")
            }
        }
    }
    
    //MARK: -  AGSPopupsContainerDelegate methods
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, wantsNewGeometryBuilderForPopup popup: AGSPopup!) -> AGSGeometryBuilder! {
        //Return an empty mutable geometry of the type that our feature layer uses
        return AGSGeometryBuilder(geometryType: (popup.geoElement as! AGSFeature).geometry.geometryType, spatialReference: self.map.spatialReference)
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, readyToEditGeometryWithBuilder geometryBuilder: AGSGeometryBuilder!, forPopup popup: AGSPopup!) {
        
        //Dismiss the popup view controller
        self.dismissViewControllerAnimated(true, completion: nil)
    
        //Prepare the current view controller for sketch mode
        self.mapView.touchDelegate = self.sketchGraphicsOverlay //activate the sketch layer
        self.mapView.callout.hidden = true
        
        //Assign the sketch layer the geometry that is being passed to us for
        //the active popup's graphic. This is the starting point of the sketch
        self.sketchGraphicsOverlay.geometryBuilder = geometryBuilder
        
        
        //zoom to the existing feature's geometry
        self.mapView.setViewpointGeometry(geometryBuilder!.toGeometry(), padding: 10, completion: nil)
        
        //hide the back button
        self.navigationItem.hidesBackButton = true
        //disable the code button
        self.navigationItem.rightBarButtonItem?.enabled = false
        //unhide the sketchToolbar
        self.sketchToolbar.hidden = false
        //disable the done button until any geometry changes
        self.doneBBI.enabled = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "geometryChanged:", name: AGSSketchGraphicsOverlayGeometryDidChangeNotification, object: nil)
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, didDeleteForPopup popup: AGSPopup!) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
        self.applyEdits()
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, didFinishEditingForPopup popup: AGSPopup!) {
        
        self.clearSketchGraphicsOverlay()
        
        //Tell the user edits are being saved int the background
        SVProgressHUD.showWithStatus("Saving feature details...")
        
        let feature = popup.geoElement as! AGSFeature
        // simplify the geometry, this will take care of self intersecting polygons and
        feature.geometry = AGSGeometryEngine.simplifyGeometry(feature.geometry)
        //normalize the geometry, this will take care of geometries that extend beyone the dateline
        //(ifwraparound was enabled on the map)
        feature.geometry = AGSGeometryEngine.normalizeCentralMeridianOfGeometry(feature.geometry)

        self.applyEdits()
        self.newFeature = nil
    }
    
    func popupsContainer(popupsContainer: AGSPopupsContainer!, didCancelEditingForPopup popup: AGSPopup!) {
        
        self.clearSketchGraphicsOverlay()

        //if we had begun adding a new feature, remove it from the layer because the user hit cancel.
        if self.newFeature != nil {
            self.featureLayer.featureTable.deleteFeature(self.newFeature, completion: { [weak self] (succeeded:Bool, error:NSError!) -> Void in
                self?.newFeature = nil
            })
        }
    }
    
    func popupsContainerDidFinishViewingPopups(popupsContainer: AGSPopupsContainer!) {
        //dismiss the popups view controller
        self.dismissViewControllerAnimated(true, completion:nil)
        self.popupsContainerVC = nil
    }
    
    func geometryChanged(notification:NSNotification) {
        //Check if the sketch geometry is valid to decide whether to enable
        //the sketchCompleteButton
        if let geometry = self.sketchGraphicsOverlay.geometry where !geometry.isEmpty() {
            self.doneBBI.enabled = true
        }
    }
    
    @IBAction func sketchDoneAction() {
        self.navigationItem.hidesBackButton = false
        self.navigationItem.rightBarButtonItem?.enabled = true
        self.presentViewController(self.popupsContainerVC, animated:true, completion:nil)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    private func clearSketchGraphicsOverlay() {
        self.mapView.touchDelegate = self
        self.sketchGraphicsOverlay.clear()
        self.sketchToolbar.hidden = true
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "FeatureTemplateSegue" {
            let controller = segue.destinationViewController as! FeatureTemplatePickerViewController
            controller.addTemplatesFromLayer(self.featureLayer)
            controller.delegate = self
        }
    }
    
    //MARK: - FeatureTemplatePickerDelegate
    
    func featureTemplatePickerViewController(controller: FeatureTemplatePickerViewController, didSelectFeatureTemplate template: AGSFeatureTemplate, forFeatureLayer featureLayer: AGSFeatureLayer) {
        
        let featureTable = self.featureLayer.featureTable as! AGSArcGISFeatureTable
        //create a new feature based on the template
        self.newFeature = featureTable.createFeatureWithTemplate(template)
        
        //set the geometry as the center of the screen
        if let visibleArea = self.mapView.visibleArea {
            self.newFeature.geometry = visibleArea.extent.center
        }
        else {
            self.newFeature.geometry = AGSPoint(x: 0, y: 0, spatialReference: self.map.spatialReference)
        }

        
        //Add the new feature to the feature layer's graphic collection
        //This is important because then the popup view controller will be able to
        //find the feature layer associated with the graphic and inspect the field metadata
        //such as domains, subtypes, data type, length, etc
        //Also note, if the user cancels before saving the new feature to the server,
        //we will manually need to remove this
        //feature from the feature layer (see implementation for popupsContainer:didCancelEditingGraphicForPopup: below)

        
        self.featureLayer.featureTable.addFeature(self.newFeature, completion: { [weak self] (succeeded:Bool, error:NSError!) -> Void in
            if let error = error {
                println("Error while adding feature :: \(error.localizedDescription)")
            }
            else if succeeded {
                if let weakSelf = self {
                    //Iniitalize a popup view controller
                    let popup = AGSPopup(geoElement: self?.newFeature)
                    
                    weakSelf.popupsContainerVC = AGSPopupsContainerViewController(popups: [popup], usingNavigationControllerStack: false)
                    weakSelf.popupsContainerVC.delegate = weakSelf
                    
                    //Only for iPad, set presentation style to Form sheet
                    //We don't want it to cover the entire screen
                    weakSelf.popupsContainerVC.modalPresentationStyle = .FormSheet
                    
                    //First, dismiss the Feature Template Picker
                    weakSelf.dismissViewControllerAnimated(false, completion:nil)
                    
                    //Next, Present the popup view controller
                    weakSelf.presentViewController(weakSelf.popupsContainerVC, animated: true) { [weak self] () -> Void in
                        self?.popupsContainerVC.startEditingCurrentPopup()
                    }
                }
            }
        })
    }
    
    func featureTemplatePickerViewControllerWantsToDismiss(controller: FeatureTemplatePickerViewController) {
        self.dismissFeatureTemplatePickerVC()
    }
    
}
