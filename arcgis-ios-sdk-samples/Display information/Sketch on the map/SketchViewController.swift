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
            // Add the sketch editor to the map view.
            mapView.sketchEditor = sketchEditor
            
            // Start a default sketch editor with the polyline creation mode.
            sketchEditor.start(with: nil, creationMode: .polyline)
            
            // Set the map.
            mapView.map = AGSMap(basemapStyle: .arcGISLightGrayBase)
            // Set the viewpoint.
            mapView.setViewpoint(AGSViewpoint(targetExtent: AGSEnvelope(xMin: -10049589.670344, yMin: 3480099.843772, xMax: -10010071.251113, yMax: 3512023.489701, spatialReference: .webMercator())))
        }
    }
    @IBOutlet var addBarButtonItem: UIBarButtonItem!
    @IBOutlet var undoBarButtonItem: UIBarButtonItem!
    @IBOutlet var redoBarButtonItem: UIBarButtonItem!
    @IBOutlet var clearBarButtonItem: UIBarButtonItem!
    @IBOutlet var statusLabel: UILabel!
    
    /// The sketch editor to use on the map.
    let sketchEditor = AGSSketchEditor()
    /// An observer for the toolbar items.
    var barItemObserver: NSObjectProtocol!
    /// Key value pairs containing the creation modes and their titles.
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
    
    // MARK: - Actions
    
    @IBAction func addGeometryButtonTapped(_ sender: UIBarButtonItem) {
        // Create an alert controller for the action sheets.
        let alertController = UIAlertController(title: "Select a creation mode", message: nil, preferredStyle: .actionSheet)
        // Create an action for each creation mode and add it to the alert controller.
        creationModes.forEach { name, mode in
            let action = UIAlertAction(title: name, style: .default) { [weak self] _ in
                self?.statusLabel.text = "\(name) selected."
                self?.sketchEditor.start(with: nil, creationMode: mode)
            }
            alertController.addAction(action)
        }
        // Add "cancel" item.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        
        // Present the action sheets when the add button is tapped.
        alertController.popoverPresentationController?.barButtonItem = addBarButtonItem
        present(alertController, animated: true)
    }
    
    @IBAction func undo() {
        // Check if there are actions to undo.
        guard sketchEditor.undoManager.canUndo else { return }
        sketchEditor.undoManager.undo()
    }
    
    @IBAction func redo() {
        // Check if there are actions to redo.
        guard sketchEditor.undoManager.canRedo else { return }
        sketchEditor.undoManager.redo()
    }
    
    @IBAction func clear() {
        self.sketchEditor.clearGeometry()
    }
    
    // MARK: - Views
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Add an observer to udate UI when needed.
        barItemObserver = NotificationCenter.default.addObserver(forName: .AGSSketchEditorGeometryDidChange, object: sketchEditor, queue: nil, using: { [unowned self] _ in
            // Enable/disable UI elements appropriately.
            undoBarButtonItem.isEnabled = sketchEditor.undoManager.canUndo
            redoBarButtonItem.isEnabled = sketchEditor.undoManager.canRedo
            clearBarButtonItem.isEnabled = sketchEditor.geometry.map { !$0.isEmpty } ?? false
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let observer = barItemObserver {
            // Remove the observer.
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SketchViewController"]
    }
}
