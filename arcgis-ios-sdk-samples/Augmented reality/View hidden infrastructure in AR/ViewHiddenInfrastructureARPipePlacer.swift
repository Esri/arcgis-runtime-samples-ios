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

class ViewHiddenInfrastructureARPipePlacer: UIViewController {
    // MARK: Storyboard views
    
    /// The label to display pipe infrastructure planning status.
    @IBOutlet var statusLabel: UILabel!
    /// The bar button to add a new geometry.
    @IBOutlet var sketchBarButtonItem: UIBarButtonItem! {
        didSet {
            sketchBarButtonItem.possibleTitles = ["Add", "Done"]
        }
    }
    /// The bar button to remove all geometries.
    @IBOutlet var trashBarButtonItem: UIBarButtonItem!
    /// The bar button to launch the AR viewer.
    @IBOutlet var cameraBarButtonItem: UIBarButtonItem!
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: .imageryWithLabelsVector())
            mapView.graphicsOverlays.add(pipeGraphicsOverlay)
            mapView.sketchEditor = AGSSketchEditor()
        }
    }
    
    // MARK: Properties
    
    /// A graphics overlay for showing the pipes.
    let pipeGraphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        overlay.renderer = AGSSimpleRenderer(
            symbol: AGSSimpleLineSymbol(style: .solid, color: .red, width: 2)
        )
        return overlay
    }()
    
    /// A KVO on the graphics array of the graphics overlay.
    var graphicsObservation: NSKeyValueObservation?
    /// The data source to track device location and provide updates to location display.
    let locationDataSource = AGSCLLocationDataSource()
    /// The elevation source with elevation service URL.
    let elevationSource = AGSArcGISTiledElevationSource(url: URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!)
    /// The elevation surface for drawing pipe graphics relative to groud level.
    let elevationSurface = AGSSurface()
    
    // MARK: Methods
    
    /// Add a graphic from the geometry of the sketch editor on current map view.
    ///
    /// - Parameters:
    ///   - polyline: A polyline geometry created by the sketch editor.
    ///   - elevationOffset: An offset added to the current elevation surface,
    ///                      to place the polyline (pipes) above or below the ground.
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
                    self.setStatus(message: "Pipe added \(elevationOffset.stringValue) meter(s) below surface.")
                } else if elevationOffset.intValue == 0 {
                    self.setStatus(message: "Pipe added at ground level.")
                } else {
                    self.setStatus(message: "Pipe added \(elevationOffset.stringValue) meter(s) above surface.")
                }
            }
            self.pipeGraphicsOverlay.graphics.add(graphic)
        }
    }
    
    // MARK: Actions
    
    @IBAction func sketchBarButtonTapped(_ sender: UIBarButtonItem) {
        guard let sketchEditor = mapView.sketchEditor else { return }
        if sender.title == "Add" {
            // Start the sketch editor when add is tapped.
            sketchEditor.start(with: nil, creationMode: .polyline)
            setStatus(message: "Tap on the map to add geometry.")
            sender.title = "Done"
        } else if sender.title == "Done" {
            // Stop the sketch editor and create graphics after done is tapped.
            if let polyline = sketchEditor.geometry as? AGSPolyline {
                presentElevationAlert { [weak self] elevation in
                    self?.addGraphicsFromSketchEditor(polyline: polyline, elevationOffset: elevation)
                }
            }
            sketchEditor.stop()
            sketchEditor.clearGeometry()
            sender.title = "Add"
        }
    }
    
    @IBAction func trashBarButtonTapped(_ sender: UIBarButtonItem) {
        pipeGraphicsOverlay.graphics.removeAllObjects()
        setStatus(message: "Tap add button to add pipes.")
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    func presentElevationAlert(completion: @escaping (NSNumber) -> Void) {
        let alert = UIAlertController(title: "Provide an elevation", message: "Between -10 and 10 meters", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.keyboardType = .numbersAndPunctuation
            textField.placeholder = "3"
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let doneAction = UIAlertAction(title: "Done", style: .default) { [textField = alert.textFields?.first] _ in
            let distanceFormatter = MeasurementFormatter()
            // Format the string to an integer.
            distanceFormatter.numberFormatter.maximumFractionDigits = 0
            
            // Ensure the elevation value is valid.
            guard let text = textField?.text,
                !text.isEmpty,
                let elevation = distanceFormatter.numberFormatter.number(from: text),
                elevation.intValue >= -10,
                elevation.intValue <= 10 else { return }
            // Pass back the elevation value.
            completion(elevation)
        }
        alert.addAction(cancelAction)
        alert.addAction(doneAction)
        alert.preferredAction = doneAction
        present(alert, animated: true)
    }
    
    // MARK: UIViewController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showViewer",
            let controller = segue.destination as? ViewHiddenInfrastructureARViewer,
            let graphics = pipeGraphicsOverlay.graphics as? [AGSGraphic] {
            controller.pipeGraphics = graphics
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "ViewHiddenInfrastructureARPipePlacer",
            "ViewHiddenInfrastructureARViewer",
            "ViewHiddenInfrastructureARCalibrationViewController"
        ]
        
        // Configure the elevation surface used to place drawn graphics relative to the ground.
        elevationSurface.elevationSources.append(elevationSource)
        elevationSource.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            }
        }
        
        // Add a KVO to update the button states.
        graphicsObservation = pipeGraphicsOverlay.observe(\.graphics, options: .initial) { [weak self] overlay, _ in
            guard let self = self else { return }
            // 'NSMutableArray' has no member 'isEmpty'; check its count instead.
            let graphicsCount = overlay.graphics.count
            let hasGraphics = graphicsCount > 0
            self.trashBarButtonItem.isEnabled = hasGraphics
            self.cameraBarButtonItem.isEnabled = hasGraphics
        }
        
        // Set location display.
        setStatus(message: "Adjusting to your current location…")
        locationDataSource.locationChangeHandlerDelegate = self
        locationDataSource.start { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
}

// MARK: - Location change handler

extension ViewHiddenInfrastructureARPipePlacer: AGSLocationChangeHandlerDelegate {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        let newViewpoint = AGSViewpoint(center: location.position!, scale: 1000)
        mapView.setViewpoint(newViewpoint, completion: nil)
        // Stop auto-adjusting when it is accurate enough.
        if location.horizontalAccuracy < 20 {
            setStatus(message: "Tap add button to add pipes.")
            sketchBarButtonItem.isEnabled = true
            locationDataSource.locationChangeHandlerDelegate = nil
            locationDataSource.stop()
        }
    }
}
