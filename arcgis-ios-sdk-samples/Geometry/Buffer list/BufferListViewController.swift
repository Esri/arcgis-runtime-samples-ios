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

class BufferListViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The create button.
    @IBOutlet weak var createBarButtonItem: UIBarButtonItem!
    /// The clear button.
    @IBOutlet weak var clearBarButtonItem: UIBarButtonItem!
    /// A label to display status message.
    @IBOutlet weak var statusLabel: UILabel!
    /// A switch to enable "union" for buffer operation.
    @IBOutlet weak var isUnionSwitch: UISwitch!
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap(imageLayer: mapImageLayer)
            mapView.graphicsOverlays.addObjects(from: [boundaryGraphicsOverlay, bufferGraphicsOverlay, tappedLocationsGraphicsOverlay])
            mapView.touchDelegate = self
        }
    }
    
    // MARK: Instance properties
    
    /// An image layer as the base layer of the map.
    let mapImageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/USA/MapServer")!)
    /// A polygon that represents the valid area of use for the spatial reference.
    let boundaryPolygon: AGSPolygon = {
        let boundaryPoints = [
            AGSPoint(x: -103.070, y: 31.720, spatialReference: .wgs84()),
            AGSPoint(x: -103.070, y: 34.580, spatialReference: .wgs84()),
            AGSPoint(x: -94.000, y: 34.580, spatialReference: .wgs84()),
            AGSPoint(x: -94.00, y: 31.720, spatialReference: .wgs84())
        ]
        let polygon = AGSPolygon(points: boundaryPoints)
        let statePlaneNorthCentralTexas = AGSSpatialReference(wkid: 32038)!
        return AGSGeometryEngine.projectGeometry(polygon, to: statePlaneNorthCentralTexas) as! AGSPolygon
    }()
    
    /// An overlay to display the boundary.
    var boundaryGraphicsOverlay: AGSGraphicsOverlay {
        let overlay = AGSGraphicsOverlay()
        let lineSymbol = AGSSimpleLineSymbol(style: .dash, color: .red, width: 5)
        let boundaryGraphic = AGSGraphic(geometry: boundaryPolygon, symbol: lineSymbol)
        overlay.graphics.add(boundaryGraphic)
        return overlay
    }
    /// An overlay to display buffers graphics.
    let bufferGraphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        let bufferPolygonOutlineSymbol = AGSSimpleLineSymbol(style: .solid, color: .systemGreen, width: 3)
        let bufferPolygonFillSymbol = AGSSimpleFillSymbol(style: .solid, color: UIColor.yellow.withAlphaComponent(0.6), outline: bufferPolygonOutlineSymbol)
        overlay.renderer = AGSSimpleRenderer(symbol: bufferPolygonFillSymbol)
        return overlay
    }()
    /// An overlay to display tapped locations with red circle symbols.
    let tappedLocationsGraphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        let circleSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
        overlay.renderer = AGSSimpleRenderer(symbol: circleSymbol)
        return overlay
    }()
    /// An array of tapped points and buffer radii (in US feet) tuple.
    var tappedPointsAndRadius = [(point: AGSPoint, radius: Double)]() {
        didSet {
            createBarButtonItem.isEnabled = !tappedPointsAndRadius.isEmpty
            clearBarButtonItem.isEnabled = !tappedPointsAndRadius.isEmpty
        }
    }
    
    /// The radius of the buffer.
    var bufferRadius: Measurement<UnitLength> = Measurement(value: 0, unit: .miles)
    /// A formatter for the output distance string.
    let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()
    
    // MARK: Instance methods
    
    /// Creates a map with an image base layer.
    ///
    /// - Parameter imageLayer: An `AGSArcGISMapImageLayer` object as the base layer of the map.
    /// - Returns: A new `AGSMap` object.
    func makeMap(imageLayer: AGSArcGISMapImageLayer) -> AGSMap {
        // The spatial reference for this sample.
        let statePlaneNorthCentralTexas = AGSSpatialReference(wkid: 32038)!
        let map = AGSMap(spatialReference: statePlaneNorthCentralTexas)
        map.basemap.baseLayers.add(imageLayer)
        return map
    }
    
    // MARK: Actions
    
    @IBAction func createButtonTapped(_ sender: UIBarButtonItem) {
        // Clear existing buffers graphics before drawing.
        bufferGraphicsOverlay.graphics.removeAllObjects()
        // Create the buffers.
        // Notice: the radius distances has the same unit of the map's spatial reference's unit.
        // In this case, the statePlaneNorthCentralTexas spatial reference uses US feet.
        if let bufferPolygon = AGSGeometryEngine.bufferGeometries(tappedPointsAndRadius.map { $0.point }, distances: tappedPointsAndRadius.map { NSNumber(value: $0.radius) }, unionResults: isUnionSwitch.isOn) {
            let graphics = bufferPolygon.map { AGSGraphic(geometry: $0, symbol: nil) }
            bufferGraphicsOverlay.graphics.addObjects(from: graphics)
            setStatus(message: "Buffers created.")
        }
    }
    
    @IBAction func clearButtonTapped(_ sender: UIBarButtonItem) {
        bufferGraphicsOverlay.graphics.removeAllObjects()
        tappedLocationsGraphicsOverlay.graphics.removeAllObjects()
        tappedPointsAndRadius.removeAll()
        setStatus(message: "Buffers removed. Tap on the map to add buffers.")
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    // MARK: UIViewController
     
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["BufferListViewController"]
        // Load the map image layer.
        mapImageLayer.load { [weak self] (error) in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
                self.setStatus(message: "Fail to load basemap.")
            } else {
                self.mapView.setViewpoint(AGSViewpoint(targetExtent: self.boundaryPolygon.extent), completion: nil)
                self.setStatus(message: "Tap on the map to add buffers.")
            }
        }
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension BufferListViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Only proceed when the tapped point is within the boundary.
        guard AGSGeometryEngine.geometry(boundaryPolygon, contains: mapPoint) else {
            setStatus(message: "Tap within the boundary to add buffer.")
            return
        }
        // Use an alert to get radius input from user.
        let alert = UIAlertController(title: "Provide a buffer radius", message: "Between 0 and 300 \(self.distanceFormatter.string(from: self.bufferRadius.unit))", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.keyboardType = .numberPad
            textField.placeholder = "100"
        }
        let doneAction = UIAlertAction(title: "Done", style: .default) { [weak self, textField = alert.textFields?.first] _ in
            guard let self = self else { return }
            // Ensure the buffer radius is valid, and is a positive value that isn't too large.
            guard let text = textField?.text,
                !text.isEmpty,
                let radius = self.distanceFormatter.numberFormatter.number(from: text),
                radius.doubleValue > 0,
                radius.doubleValue < 300 else {
                    self.setStatus(message: "Tap on the map to add buffers.")
                    return
            }
            // Update the buffer radius with the text value.
            self.bufferRadius.value = radius.doubleValue
            // The spatial reference in this sample uses US feet as its unit.
            let radiusInFeet = self.bufferRadius.converted(to: .feet).value
            // Create and add graphic symbolizing the tap point.
            let pointGraphic = AGSGraphic(geometry: mapPoint, symbol: nil)
            self.tappedLocationsGraphicsOverlay.graphics.add(pointGraphic)
            // Keep track of tapped points and their radii.
            self.tappedPointsAndRadius.append((point: mapPoint, radius: radiusInFeet))
            self.setStatus(message: "Buffer center point added.")
        }
        alert.addAction(doneAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        alert.preferredAction = doneAction
        present(alert, animated: true)
    }
}
