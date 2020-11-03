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
    
    /// The undo button.
    @IBOutlet weak var undoBarButtonItem: UIBarButtonItem!
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
            // Create and add graphics overlays.
            
            // An overlay to display the boundary.
            let boundaryGraphicsOverlay = makeBoundaryGraphicsOverlay(boundaryGeometry: boundaryPolygon)
            bufferGraphicsOverlay = makeBufferGraphicsOverlay()
            tappedLocationsGraphicsOverlay = makeTappedLocationsGraphicsOverlay()
            mapView.graphicsOverlays.addObjects(from: [boundaryGraphicsOverlay, bufferGraphicsOverlay!, tappedLocationsGraphicsOverlay!])
            
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
    
    /// An overlay to display buffers graphics.
    var bufferGraphicsOverlay: AGSGraphicsOverlay!
    /// An overlay to display tapped locations with red circle symbols.
    var tappedLocationsGraphicsOverlay: AGSGraphicsOverlay!
    /// An array of tapped points and buffer radii (in US feet) tuple.
    var tappedPointsAndRadii = [(point: AGSPoint, radius: Double)]() {
        didSet {
            let newValueIsEmpty = tappedPointsAndRadii.isEmpty
            if newValueIsEmpty != oldValue.isEmpty {
                // Only set button states when the emptiness of the array has changed.
                undoBarButtonItem.isEnabled = !newValueIsEmpty
                clearBarButtonItem.isEnabled = !newValueIsEmpty
            }
            // Redraw the buffers.
            drawBuffers()
        }
    }
    
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
    
    /// Creates a graphics overlay for the boundary polygon graphics.
    ///
    /// - Parameter boundaryGeometry: The geometry of bounday graphics.
    /// - Returns: A new `AGSGraphicsOverlay` object.
    func makeBoundaryGraphicsOverlay(boundaryGeometry: AGSGeometry) -> AGSGraphicsOverlay {
        let overlay = AGSGraphicsOverlay()
        let lineSymbol = AGSSimpleLineSymbol(style: .dash, color: .red, width: 5)
        let boundaryGraphic = AGSGraphic(geometry: boundaryGeometry, symbol: lineSymbol)
        overlay.graphics.add(boundaryGraphic)
        return overlay
    }
    
    /// Creates a graphics overlay for the buffer graphics.
    func makeBufferGraphicsOverlay() -> AGSGraphicsOverlay {
        let overlay = AGSGraphicsOverlay()
        let bufferPolygonOutlineSymbol = AGSSimpleLineSymbol(style: .solid, color: .systemGreen, width: 3)
        let bufferPolygonFillSymbol = AGSSimpleFillSymbol(style: .solid, color: UIColor.yellow.withAlphaComponent(0.6), outline: bufferPolygonOutlineSymbol)
        overlay.renderer = AGSSimpleRenderer(symbol: bufferPolygonFillSymbol)
        return overlay
    }
    
    /// Creates a graphics overlay for the tapped location graphics.
    func makeTappedLocationsGraphicsOverlay() -> AGSGraphicsOverlay {
        let overlay = AGSGraphicsOverlay()
        let circleSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
        overlay.renderer = AGSSimpleRenderer(symbol: circleSymbol)
        return overlay
    }
    
    // MARK: Actions
    
    @IBAction func undoButtonTapped(_ sender: UIBarButtonItem) {
        // Remove the last pair of tapped point and radius.
        tappedPointsAndRadii.removeLast()
    }
    
    @IBAction func isUnionSwitchValueChanged(_ sender: UISwitch) {
        // Redraw buffers when the union switch's value is changed.
        drawBuffers()
    }
    
    @IBAction func clearButtonTapped(_ sender: UIBarButtonItem) {
        bufferGraphicsOverlay.graphics.removeAllObjects()
        tappedLocationsGraphicsOverlay.graphics.removeAllObjects()
        tappedPointsAndRadii.removeAll()
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    func drawBuffers() {
        // Clear existing buffers graphics before drawing.
        bufferGraphicsOverlay.graphics.removeAllObjects()
        tappedLocationsGraphicsOverlay.graphics.removeAllObjects()
        
        guard !tappedPointsAndRadii.isEmpty else {
            setStatus(message: "Tap on the map to add buffers.")
            return
        }
        
        // Reduce the tuples into points and radii arrays.
        let (points, radii) = tappedPointsAndRadii.reduce(into: ([AGSPoint](), [NSNumber]())) { (result, pointAndRadius) in
            result.0.append(pointAndRadius.point)
            result.1.append(pointAndRadius.radius as NSNumber)
        }
        // Create the buffers.
        // Notice: the radius distances has the same unit of the map's spatial reference's unit.
        // In this case, the statePlaneNorthCentralTexas spatial reference uses US feet.
        if let bufferPolygon = AGSGeometryEngine.bufferGeometries(points, distances: radii, unionResults: isUnionSwitch.isOn) {
            // Add graphics symbolizing the tap point.
            tappedLocationsGraphicsOverlay.graphics.addObjects(from: points.map { AGSGraphic(geometry: $0, symbol: nil) })
            // Add graphics of the buffer polygons.
            bufferGraphicsOverlay.graphics.addObjects(from: bufferPolygon.map { AGSGraphic(geometry: $0, symbol: nil) })
            setStatus(message: "Buffers created.")
        }
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
                self.setStatus(message: "Failed to load basemap.")
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
        let alert = UIAlertController(title: "Provide a buffer radius between 0 and 300 \(distanceFormatter.string(from: UnitLength.miles)).", message: nil, preferredStyle: .alert)
        // Create an object to observe changes from the textfield.
        var textFieldObserver: NSObjectProtocol!
        // Add a textfield to get user input.
        alert.addTextField { textField in
            textField.keyboardType = .numberPad
            textField.placeholder = "100"
        }
        
        let doneAction = UIAlertAction(title: "Done", style: .default) { [weak self, unowned alert, mapPoint = mapPoint] _ in
            // Remove the observer after editing is complete.
            NotificationCenter.default.removeObserver(textFieldObserver!)
            
            guard let self = self,
                  let text = alert.textFields?.first?.text,
                  let radius = self.distanceFormatter.numberFormatter.number(from: text)
            else { return }
            
            // Update the buffer radius with the text value.
            let radiusInMiles = Measurement(value: radius.doubleValue, unit: UnitLength.miles)
            // The spatial reference in this sample uses US feet as its unit.
            let radiusInFeet = radiusInMiles.converted(to: .feet).value
            
            // Keep track of tapped points and their radii.
            self.tappedPointsAndRadii.append((point: mapPoint, radius: radiusInFeet))
        }
        
        // Add an observer to ensure the user input is valid.
        textFieldObserver = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: nil, queue: .main, using: { [weak self, weak alert, unowned doneAction] _ in
            // Ensure the buffer radius input is valid, and is within the range.
            if let text = alert?.textFields?.first?.text,
               !text.isEmpty,
               let radius = self?.distanceFormatter.numberFormatter.number(from: text),
               radius.doubleValue > 0,
               radius.doubleValue < 300 {
                doneAction.isEnabled = true
            } else {
                doneAction.isEnabled = false
            }
        })
        // Disable done button by default.
        doneAction.isEnabled = false
        alert.addAction(doneAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // Remove the observer when canceled.
            NotificationCenter.default.removeObserver(textFieldObserver!)
        }
        alert.addAction(cancelAction)
        alert.preferredAction = doneAction
        present(alert, animated: true)
    }
}
