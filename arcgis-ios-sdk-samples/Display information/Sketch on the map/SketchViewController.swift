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
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Configure the sketch editor.
            sketchEditor = AGSSketchEditor()
            mapView.sketchEditor = sketchEditor
            
            // Start a default sketch editor with the polyline creation mode.
            sketchEditor.start(with: nil, creationMode: .polyline)
            
            // Set the map.
            mapView.map = AGSMap(basemapStyle: .arcGISLightGrayBase)
            mapView.interactionOptions.isMagnifierEnabled = true
            // Set the viewpoint.
            mapView.setViewpoint(AGSViewpoint(targetExtent: AGSEnvelope(xMin: -10049589.670344, yMin: 3480099.843772, xMax: -10010071.251113, yMax: 3512023.489701, spatialReference: .webMercator())))
        }
    }
    @IBOutlet var addBarButtonItem: UIBarButtonItem!
    @IBOutlet var undoBBI: UIBarButtonItem!
    @IBOutlet var redoBBI: UIBarButtonItem!
    @IBOutlet var clearBBI: UIBarButtonItem!
    
    var sketchEditor: AGSSketchEditor!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SketchViewController"]
    }
    
    // MARK: - Actions
    
    @IBAction func addGeometry() {
        // Create an alert controller for the action sheets.
        let alertController = UIAlertController(title: "Select a creation mode", message: nil, preferredStyle: .actionSheet)
        // Key value pairs containing the creation modes and their titles.
        let creationModes: KeyValuePairs = [
            "Arrow": AGSSketchCreationMode.arrow,
            "Ellipse": .ellipse,
            "FreehandPolygon": .freehandPolygon,
            "FreehandPolyline": .freehandPolyline,
            "Multipoint": .multipoint,
            "Point": .point,
            "Polygon": .polygon,
            "Polyline": .polyline,
            "Rectangle": .rectangle,
            "Triangle": .triangle
        ]
        // Create an action for each creation mode and add it to the alert controller.
        creationModes.forEach { creationMode in
            let action = UIAlertAction(title: creationMode.key, style: .default) { (_) in
                self.sketchEditor.start(with: nil, creationMode: creationMode.value)
            }
            alertController.addAction(action)
        }
        // Add "cancel" item.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Present the action sheets when the add button is tapped.
        alertController.popoverPresentationController?.barButtonItem = addBarButtonItem
        present(alertController, animated: true)
        // Reset the sketch editor.
        self.mapView.sketchEditor = self.sketchEditor
    }
    
    @IBAction func undo() {
        // Check if there are actions to undo.
        if self.sketchEditor.undoManager.canUndo {
            self.sketchEditor.undoManager.undo()
        }
    }
    
    @IBAction func redo() {
        // Check if there are actions to redo.
        if self.sketchEditor.undoManager.canRedo {
            self.sketchEditor.undoManager.redo()
        }
    }
    
    @IBAction func clear() {
        self.sketchEditor.clearGeometry()
    }
}
