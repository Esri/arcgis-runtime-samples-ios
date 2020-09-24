// Copyright 2020 Esri
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
import ArcGISToolkit

class ViewHiddenInfrastructureARPipePlacer: UIViewController {
    /// The label to display route-planning status.
    @IBOutlet var statusLabel: UILabel!
    /// The bar button to add a new geometry.
    @IBOutlet var sketchBarButtonItem: UIBarButtonItem! {
        didSet {
            sketchBarButtonItem.possibleTitles = ["Add", "Done"]
        }
    }
    /// The bar button to remove all geometries.
    @IBOutlet var trashBarButtonItem: UIBarButtonItem!
    /// The bar button to redo an edit in sketch editor.
    @IBOutlet var redoBarButtonItem: UIBarButtonItem!
    /// The bar button to undo an edit in sketch editor.
    @IBOutlet var undoBarButtonItem: UIBarButtonItem!
    /// The bar button to launch the AR viewer.
    @IBOutlet var cameraBarButtonItem: UIBarButtonItem!
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: .imageryWithLabelsVector())
            mapView.graphicsOverlays.add(pipeGraphicsOverlay)
            mapView.sketchEditor = AGSSketchEditor()
            mapView.locationDisplay.dataSource = locationDataSource
//            mapView.touchDelegate = self
        }
    }
    /// The data source to track device location and provide updates to location display.
    let locationDataSource = AGSCLLocationDataSource()
    
    /// The KVO on draw status of the map view.
    private var graphicsObservation: NSKeyValueObservation?
    
    /// A graphics overlay for showing the pipes.
    let pipeGraphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        overlay.renderer = AGSSimpleRenderer(
            symbol: AGSSimpleLineSymbol(style: .solid, color: .yellow, width: 2)
        )
        
        return overlay
    }()
    
    /// The elevation source with elevation service URL.
    let elevationSource = AGSArcGISTiledElevationSource(url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
    /// The elevation surface for drawing pipe graphics relative to groud level.
    let elevationSurface = AGSSurface()
    
    // MARK: Actions
    
    @IBAction func undo(_ sender: UIBarButtonItem) {
        guard let sketchEditor = mapView.sketchEditor else { return }
        if sketchEditor.undoManager.canUndo {
            sketchEditor.undoManager.undo()
        }
        setButtonStateOnGeometryChanged(sketchEditor: sketchEditor)
    }
    
    @IBAction func redo(_ sender: UIBarButtonItem) {
        guard let sketchEditor = mapView.sketchEditor else { return }
        if sketchEditor.undoManager.canRedo {
            sketchEditor.undoManager.redo()
        }
        setButtonStateOnGeometryChanged(sketchEditor: sketchEditor)
    }
    
    @IBAction func sketchBarButtonTapped(_ sender: UIBarButtonItem) {
        guard let sketchEditor = mapView.sketchEditor else { return }
        setButtonStateOnGeometryChanged(sketchEditor: sketchEditor)
        if sender.title == "Add" {
            sketchEditor.start(with: nil, creationMode: .polyline)
            setStatus(message: "Tap on the map to add geometry.")
            sender.title = "Done"
        } else if sender.title == "Done" {
            if let polyline = sketchEditor.geometry as? AGSPolyline {
                presentElevationAlert { [weak self] elevation in
                    self?.addGraphicsFromSketchEditor(polyline: polyline, elevationOffset: elevation)
                }
                sketchEditor.clearGeometry()
            }
            sender.title = "Add"
        }
    }
    
    @IBAction func trashBarButtonTapped(_ sender: UIBarButtonItem) {
        pipeGraphicsOverlay.graphics.removeAllObjects()
    }
    
    func addGraphicsFromSketchEditor(polyline: AGSPolyline, elevationOffset: NSNumber) {
        guard let firstpoint = polyline.parts.array().first?.startPoint else { return }
        elevationSurface.elevation(for: firstpoint) { [weak self] (elevation: Double, error: Error?) in
            guard let self = self else { return }
            let graphic: AGSGraphic
            if error != nil {
                graphic = AGSGraphic(geometry: polyline, symbol: nil)
                self.setStatus(message: "Pipe added without elevation.")
            } else {
                let elevatedPolyline = AGSGeometryEngine.geometry(bySettingZ: elevation + elevationOffset.doubleValue, in: polyline)
                graphic = AGSGraphic(geometry: elevatedPolyline, symbol: nil)
                if elevationOffset.intValue < 0 {
                    self.setStatus(message: "Pipe added \(elevationOffset.stringValue) below surface.")
                } else if elevationOffset.intValue == 0 {
                    self.setStatus(message: "Pipe added at ground level.")
                } else {
                    self.setStatus(message: "Pipe added \(elevationOffset.stringValue) above surface.")
                }
            }
            self.pipeGraphicsOverlay.graphics.add(graphic)
            self.cameraBarButtonItem.isEnabled = true
        }
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    func setButtonStateOnGeometryChanged(sketchEditor: AGSSketchEditor) {
        undoBarButtonItem.isEnabled = sketchEditor.undoManager.canUndo
        redoBarButtonItem.isEnabled = sketchEditor.undoManager.canRedo
    }
    
    func presentElevationAlert(completion: @escaping (NSNumber) -> Void) {
        let alert = UIAlertController(title: "Provide an elevation", message: "Between -10 and 10 meters", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.keyboardType = .numbersAndPunctuation
            textField.placeholder = "3"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        let doneAction = UIAlertAction(title: "Done", style: .default) { [textField = alert.textFields?.first] _ in
            let distanceFormatter = MeasurementFormatter()
            // Format the string to an integer.
            distanceFormatter.numberFormatter.maximumFractionDigits = 0
                
            // Ensure the elevation value is valid.
            guard let text = textField?.text,
                !text.isEmpty,
                let elevation = distanceFormatter.numberFormatter.number(from: text),
                elevation.doubleValue >= -10,
                elevation.doubleValue <= 10 else { return }
            // Pass back the elevation value.
            completion(elevation)
        }
        alert.addAction(doneAction)
        alert.preferredAction = doneAction
        present(alert, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showViewer", let controller = segue.destination as? ViewHiddenInfrastructureARViewer {
            controller.pipeGraphics = pipeGraphicsOverlay.graphics as! [AGSGraphic]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["ViewHiddenInfrastructureARPipePlacer"]
        
        // Configure the elevation surface used to place drawn graphics relative to the ground.
        elevationSurface.elevationSources.append(elevationSource)
        elevationSource.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.sketchBarButtonItem.isEnabled = true
            }
        }
        // Add a KVO
        graphicsObservation = pipeGraphicsOverlay.observe(\.graphics, options: .initial) { [weak self] overlay, _ in
            guard let self = self else { return }
            // 'NSMutableArray' has no member 'isEmpty'; check its count instead.
            let graphicsCount = overlay.graphics.count
            let hasGraphics = graphicsCount > 0
            self.trashBarButtonItem.isEnabled = hasGraphics
            self.cameraBarButtonItem.isEnabled = hasGraphics
        }
        
        mapView.locationDisplay.start()
    }
}
