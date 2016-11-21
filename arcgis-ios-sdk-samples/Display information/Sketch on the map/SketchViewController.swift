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
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var geometrySegmentedControl:UISegmentedControl!
    @IBOutlet private weak var undoBBI:UIBarButtonItem!
    @IBOutlet private weak var redoBBI:UIBarButtonItem!
    @IBOutlet private weak var clearBBI:UIBarButtonItem!
    
    
    private var map:AGSMap!
    private var sketchEditor:AGSSketchEditor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SketchViewController"]
        
        self.map = AGSMap(basemap: AGSBasemap.lightGrayCanvasBasemap())
        
        self.sketchEditor = AGSSketchEditor()
        self.mapView.sketchEditor =  self.sketchEditor
        
        self.sketchEditor.startWithGeometryType(.Polyline)
        
        self.mapView.map = self.map
        self.mapView.interactionOptions.magnifierEnabled = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SketchViewController.respondToGeomChanged), name: AGSSketchEditorGeometryDidChangeNotification, object: nil)
        
        //set initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(targetExtent: AGSEnvelope(XMin: -10049589.670344, yMin: 3480099.843772, xMax: -10010071.251113, yMax: 3512023.489701, spatialReference: AGSSpatialReference.webMercator()))
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func respondToGeomChanged() {
        //Enable/disable UI elements appropriately
        self.undoBBI.enabled = self.sketchEditor.undoManager.canUndo
        self.redoBBI.enabled = self.sketchEditor.undoManager.canRedo
        self.clearBBI.enabled = self.sketchEditor.geometry != nil && !self.sketchEditor.geometry!.empty
    }
    
    //MARK: - Actions
    
    @IBAction func geometryValueChanged(segmentedControl:UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0://point
            self.sketchEditor.startWithGeometryType(.Point)
            
        case 1://polyline
            self.sketchEditor.startWithGeometryType(.Polyline)
            
        case 2://polygon
            self.sketchEditor.startWithGeometryType(.Polygon)
        default:
            break
        }
        self.mapView.sketchEditor = self.sketchEditor
    }
    
    @IBAction func undo() {
        if self.sketchEditor.undoManager.canUndo { //extra check, just to be sure
            self.sketchEditor.undoManager.undo()
        }
    }
    
    @IBAction func redo() {
        if self.sketchEditor.undoManager.canRedo { //extra check, just to be sure
            self.sketchEditor.undoManager.redo()
        }
    }
    
    @IBAction func clear() {
        self.sketchEditor.clearGeometry()
    }
}
