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

class SketchToolbar: NSObject, AGSMapViewTouchDelegate {
    
    var sketchLayer:AGSSketchGraphicsLayer!
    var mapView:AGSMapView!
    var graphicsLayer:AGSGraphicsLayer!
    
    var sketchTools:UISegmentedControl!
    var undoTool:UIButton!
    var redoTool:UIButton!
    var saveTool:UIButton!
    var clearTool:UIButton!
    
    var activeGraphic:AGSGraphic!
    
    init(toolbar:UIToolbar, sketchLayer:AGSSketchGraphicsLayer, mapView:AGSMapView, graphicsLayer:AGSGraphicsLayer) {
        
        //hold references to the mapView, graphicsLayer, and sketchLayer
        self.sketchLayer = sketchLayer
        self.mapView = mapView
        self.graphicsLayer = graphicsLayer
        
        //Get references to the UI elements in the toolbar
        //Each UI element was assigned a "tag" in the nib file to make it easy to find them
        self.sketchTools = toolbar.viewWithTag(55) as! UISegmentedControl
        
        //to display actual images in iOS 7 for segmented control
        let version = (UIDevice.currentDevice().systemVersion as NSString).integerValue
        if version >= 7 {
            let index = self.sketchTools.numberOfSegments
            for var i = 0; i < index; i++ {
                let image = self.sketchTools.imageForSegmentAtIndex(i)
                let newImage = image?.imageWithRenderingMode(.AlwaysOriginal)
                self.sketchTools.setImage(newImage, forSegmentAtIndex:i)
            }
        }
        
        
        //disable the select tool if no graphics available
        self.sketchTools.setEnabled(graphicsLayer.graphicsCount > 0, forSegmentAtIndex: 3)
        
        self.undoTool = toolbar.viewWithTag(56) as! UIButton
        self.redoTool = toolbar.viewWithTag(57) as! UIButton
        self.saveTool = toolbar.viewWithTag(58) as! UIButton
        self.clearTool = toolbar.viewWithTag(59) as! UIButton
        
        super.init()
        
        //Set target-actions for the UI elements in the toolbar
        self.sketchTools.addTarget(self, action:"toolSelected", forControlEvents:.ValueChanged)
        self.undoTool.addTarget(self, action:"undo", forControlEvents:.TouchUpInside)
        self.redoTool.addTarget(self, action:"redo", forControlEvents:.TouchUpInside)
        self.saveTool.addTarget(self, action:"save", forControlEvents:.TouchUpInside)
        self.clearTool.addTarget(self, action:"clear", forControlEvents:.TouchUpInside)
        
        //Register for "Geometry Changed" notifications
        //We want to enable/disable UI elements when sketch geometry is modified
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"respondToGeomChanged", name:AGSSketchGraphicsLayerGeometryDidChangeNotification, object:nil)
        
        //call this so we can properly initialize the state of undo,redo,clear, and save
        self.respondToGeomChanged()
    }
    
    func respondToGeomChanged() {
        //Enable/disable UI elements appropriately
        self.undoTool.enabled = self.sketchLayer.undoManager.canUndo
        self.redoTool.enabled = self.sketchLayer.undoManager.canRedo
        self.clearTool.enabled = self.sketchLayer.geometry != nil && !self.sketchLayer.geometry.isEmpty()
        self.saveTool.enabled = self.sketchLayer.geometry != nil && self.sketchLayer.geometry.isValid()
    }
    
    @IBAction func undo() {
        if self.sketchLayer.undoManager.canUndo { //extra check, just to be sure
            self.sketchLayer.undoManager.undo()
        }
    }
    
    @IBAction func redo() {
        if self.sketchLayer.undoManager.canRedo { //extra check, just to be sure
            self.sketchLayer.undoManager.redo()
        }
    }
    
    @IBAction func clear() {
        self.sketchLayer.clear()
    }
    
    @IBAction func save() {
        //Get the sketch geometry
        let sketchGeometry = self.sketchLayer.geometry.copy() as! AGSGeometry
        
        //If this is not a new sketch (i.e we are modifying an existing graphic)
        if self.activeGraphic != nil {
            //Modify the existing graphic giving it the new geometry
            self.activeGraphic.geometry = sketchGeometry
            self.activeGraphic = nil
            
            //Re-enable the sketch tools
            self.sketchTools.setEnabled(true, forSegmentAtIndex: 0)
            self.sketchTools.setEnabled(true, forSegmentAtIndex: 1)
            self.sketchTools.setEnabled(true, forSegmentAtIndex: 2)
            self.sketchTools.setEnabled(true, forSegmentAtIndex: 3)
            
        }else {
            //Add a new graphic to the graphics layer
            let graphic = AGSGraphic(geometry: sketchGeometry, symbol: nil, attributes: nil)
            self.graphicsLayer.addGraphic(graphic)
            
            //enable the select tool if there is atleast one graphic to select
            self.sketchTools.setEnabled(self.graphicsLayer.graphicsCount > 0, forSegmentAtIndex: 3)
            
        }
        
        self.sketchLayer.clear()
        self.sketchLayer.undoManager.removeAllActions()
    }
    
    @IBAction func toolSelected() {
        switch self.sketchTools.selectedSegmentIndex {
        case 0://point tool
            //sketch layer should begin tracking touch events to sketch a point
            self.mapView.touchDelegate = self.sketchLayer
            self.sketchLayer.geometry = AGSMutablePoint(spatialReference: self.mapView.spatialReference)
            self.sketchLayer.undoManager.removeAllActions()
            
        case 1://polyline tool
            //sketch layer should begin tracking touch events to sketch a polyline
            self.mapView.touchDelegate = self.sketchLayer
            self.sketchLayer.geometry = AGSMutablePolyline(spatialReference: self.mapView.spatialReference)
            self.sketchLayer.undoManager.removeAllActions()
            
        case 2://polygon tool
            //sketch layer should begin tracking touch events to sketch a polygon
            self.mapView.touchDelegate = self.sketchLayer
            self.sketchLayer.geometry = AGSMutablePolygon(spatialReference: self.mapView.spatialReference)
            self.sketchLayer.undoManager.removeAllActions()
            
        case 3: //select tool
            //nothing to sketch
            self.sketchLayer.geometry = nil
            
            //We will track touch events to find which graphic to modify
            self.mapView.touchDelegate = self
            
        default:
            break
        }
        
    }
    
    func mapView(mapView: AGSMapView!, didClickAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        
        //find which graphic to modify
        let valuesArray = Array(features.values)
        for graphicsArray in valuesArray as! [[AGSGraphic]] {
            if graphicsArray.count > 0 {
                //Get the graphic's geometry to the sketch layer so that it can be modified
                self.activeGraphic = graphicsArray[0]
                let geom = self.activeGraphic.geometry.mutableCopy() as! AGSGeometry
                
                //clear out the graphic's geometry so that it is not displayed under the sketch
                self.activeGraphic.geometry = nil
                
                //Feed the graphic's geometry to the sketch layer so that user can modify it
                self.sketchLayer.geometry = geom
                self.sketchLayer.undoManager.removeAllActions()
                
                //sketch layer should begin tracking touch events to modify the sketch
                self.mapView.touchDelegate = self.sketchLayer
                
                //Disable other tools until we finish modifying a graphic
                self.sketchTools.setEnabled(false, forSegmentAtIndex: 0)
                self.sketchTools.setEnabled(false, forSegmentAtIndex: 1)
                self.sketchTools.setEnabled(false, forSegmentAtIndex: 2)
                self.sketchTools.setEnabled(false, forSegmentAtIndex: 3)
                
                //Activate the appropriate sketch tool
                if geom is AGSPoint {
                    self.sketchTools.selectedSegmentIndex = 0
                }
                else if geom is AGSPolyline {
                    self.sketchTools.selectedSegmentIndex = 1
                }
                else if geom is AGSPolygon {
                    self.sketchTools.selectedSegmentIndex = 2
                }
            }
        }
    }
}
