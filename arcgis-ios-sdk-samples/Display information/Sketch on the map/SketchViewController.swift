// Copyright 2016 Esri.
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

class SketchViewController: UIViewController {

    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var geometrySegmentedControl:UISegmentedControl!
    @IBOutlet private var sketchStyleSegmentedControl:UISegmentedControl!
    @IBOutlet private var undoBBI:UIBarButtonItem!
    @IBOutlet private var redoBBI:UIBarButtonItem!
    @IBOutlet private var clearBBI:UIBarButtonItem!
    
    
    private var map:AGSMap!
    private var geometrySketchEditor:AGSGeometrySketchEditor!
    private var freehandSketchEditor:AGSFreehandSketchEditor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SketchViewController"]
        
        //instantiate map with basemap
        self.map = AGSMap(basemap: AGSBasemap.lightGrayCanvasBasemap())
        
        //assign map to map view
        self.mapView.map = self.map
        
        //enable magnifier on map view (visible on long press)
        self.mapView.magnifierEnabled = true
        
        //instantiate geometry sketch editor
        self.geometrySketchEditor = AGSGeometrySketchEditor()
        self.geometrySketchEditor.geometryBuilder = AGSPolylineBuilder(spatialReference: AGSSpatialReference.webMercator())
        
        //by default geometry sketch editor is selected, 
        //so assign it to the map view
        self.mapView.sketchEditor =  self.geometrySketchEditor
        
        //instantiate freehand sketch editor
        self.freehandSketchEditor = AGSFreehandSketchEditor()
        
        //enable both sketch editors, so that we dont have to do
        //it when user switch between them
        self.geometrySketchEditor.enabled = true
        self.freehandSketchEditor.enabled = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SketchViewController.respondToGeomChanged), name: AGSSketchEditorSketchDidChangeNotification, object: nil)

        //set initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(XMin: -10049589.670344, yMin: 3480099.843772, xMax: -10010071.251113, yMax: 3512023.489701, spatialReference: AGSSpatialReference.webMercator()))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func respondToGeomChanged() {
        //Enable/disable UI elements appropriately
        self.undoBBI.enabled = self.mapView.sketchEditor!.undoManager.canUndo
        self.redoBBI.enabled = self.mapView.sketchEditor!.undoManager.canRedo
        
        if self.mapView.sketchEditor! == self.geometrySketchEditor {
            self.clearBBI.enabled = self.geometrySketchEditor.geometryBuilder != nil && !self.geometrySketchEditor.geometryBuilder!.isEmpty()
        }
        else {
            self.clearBBI.enabled = self.freehandSketchEditor.geometries.count > 0
        }
    }
    
    //MARK: - Actions
    
    @IBAction func sketchStyleChanged(segmentedControl: UISegmentedControl) {
        
        if segmentedControl.selectedSegmentIndex == 0 {
            //assign geometry sketch editor to map view
            self.mapView.sketchEditor = self.geometrySketchEditor
            
            //enable point segment
            self.geometrySegmentedControl.setEnabled(true, forSegmentAtIndex: 0)
        }
        else {
            //assign freehand sketch editor to map view
            self.mapView.sketchEditor = self.freehandSketchEditor
            
            //disable point segment as freehand does not support points
            self.geometrySegmentedControl.setEnabled(false, forSegmentAtIndex: 0)
        }
        
        //switch to polyline
        self.geometrySegmentedControl.selectedSegmentIndex = 1
        
        //call respondToGeomChanged() to update the bar button items
        self.respondToGeomChanged()
    }
    
    @IBAction func geometryValueChanged(segmentedControl:UISegmentedControl) {
        if self.sketchStyleSegmentedControl.selectedSegmentIndex == 0 {
            switch segmentedControl.selectedSegmentIndex {
            case 0://point
                self.geometrySketchEditor.geometryBuilder = AGSPointBuilder(spatialReference: AGSSpatialReference.webMercator())
                
            case 1://polyline
                self.geometrySketchEditor.geometryBuilder = AGSPolylineBuilder(spatialReference: AGSSpatialReference.webMercator())
                
            case 2://polygon
                self.geometrySketchEditor.geometryBuilder = AGSPolygonBuilder(spatialReference: AGSSpatialReference.webMercator())
                
            default:
                break
            }
            
            //remove all actions from undo manager
            self.mapView.sketchEditor!.undoManager.removeAllActions()
        }
        else {
            switch segmentedControl.selectedSegmentIndex {
            case 1: //polyline
                self.freehandSketchEditor.currentGeometryType = .Polyline
            default:    //polygon
                self.freehandSketchEditor.currentGeometryType = .Polygon
            }
        }
    }
    
    @IBAction func undo() {
        if self.mapView.sketchEditor!.undoManager.canUndo { //extra check, just to be sure
            self.mapView.sketchEditor!.undoManager.undo()
        }
    }
    
    @IBAction func redo() {
        if self.mapView.sketchEditor!.undoManager.canRedo { //extra check, just to be sure
            self.mapView.sketchEditor!.undoManager.redo()
        }
    }
    
    @IBAction func clear() {
        //TODO: remove the work around once clear() is part of super class
        if self.mapView.sketchEditor! == self.geometrySketchEditor {
            self.geometrySketchEditor.clear()
        }
        else {
            self.freehandSketchEditor.clear()
        }
    }
}
