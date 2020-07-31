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
    
    /// A label to display status message.
    @IBOutlet weak var statusLabel: UILabel!
    /// A label to display current radius slider distance value.
    @IBOutlet weak var radiusLabel: UILabel! {
        didSet {
            distanceSliderValueChanged(distanceSlider)
        }
    }
    /// A switch to control either to union results or not for buffer operation.
    @IBOutlet weak var isUnionSwitch: UISwitch!
    /// A slider to adjust the radius distance of a buffer.
    @IBOutlet weak var distanceSlider: UISlider!
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.graphicsOverlays.addObjects(from: [boundaryGraphicsOverlay, bufferGraphicsOverlay, tapLocationsGraphicsOverlay])
            mapView.touchDelegate = self
        }
    }
    
    // MARK: Instance properties
    
    /// An image layer serve as the base layer of the map.
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
        let boundaryGraphicsOverlay = AGSGraphicsOverlay()
        let lineSymbol = AGSSimpleLineSymbol(style: .dash, color: .red, width: 5)
        let boundaryGraphic = AGSGraphic(geometry: boundaryPolygon, symbol: lineSymbol)
        boundaryGraphicsOverlay.graphics.add(boundaryGraphic)
        return boundaryGraphicsOverlay
    }
    /// An overlay to display buffers graphics.
    let bufferGraphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        let bufferPolygonOutlineSymbol = AGSSimpleLineSymbol(style: .solid, color: .systemGreen, width: 3)
        let bufferPolygonFillSymbol = AGSSimpleFillSymbol(style: .solid, color: UIColor.yellow.withAlphaComponent(0.6), outline: bufferPolygonOutlineSymbol)
        overlay.renderer = AGSSimpleRenderer(symbol: bufferPolygonFillSymbol)
        return overlay
    }()
    /// An overlay to display tapped locations with red circle symbol.
    let tapLocationsGraphicsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()
        let circleSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
        overlay.renderer = AGSSimpleRenderer(symbol: circleSymbol)
        return overlay
    }()
    /// An array of tapped points and buffer radius (in US feet) tuple.
    var tappedPointsAndRadius = [(point: AGSPoint, radius: Double)]()
    
    /// The radius of the buffer.
    var bufferRadius: Measurement<UnitLength> = Measurement(value: 100, unit: .miles) {
        didSet {
            radiusLabel.text = distanceFormatter.string(from: bufferRadius)
        }
    }
    /// A formatter to format the output distance string.
    let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .short
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()
    
    // MARK: Instance methods
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        // The spatial reference for this sample.
        let statePlaneNorthCentralTexas = AGSSpatialReference(wkid: 32038)!
        let map = AGSMap(spatialReference: statePlaneNorthCentralTexas)
        map.basemap.baseLayers.add(mapImageLayer)
        map.initialViewpoint = AGSViewpoint(targetExtent: boundaryPolygon.extent)
        return map
    }
    
    // MARK: Actions
    
    @IBAction func createButtonTapped(_ sender: UIBarButtonItem) {
        // Clear existing buffers graphics before drawing.
        bufferGraphicsOverlay.graphics.removeAllObjects()
        // Create the buffers.
        // Notice: the radius distances has the same unit of the map's spatial reference's unit.
        if let bufferPolygon = AGSGeometryEngine.bufferGeometries(tappedPointsAndRadius.map { $0.point }, distances: tappedPointsAndRadius.map { NSNumber(value: $0.radius) }, unionResults: isUnionSwitch.isOn) {
            let graphics = bufferPolygon.map { AGSGraphic(geometry: $0, symbol: nil) }
            bufferGraphicsOverlay.graphics.addObjects(from: graphics)
            setStatus(message: "Buffers created.")
        }
    }
    
    @IBAction func clearButtonTapped(_ sender: UIBarButtonItem) {
        bufferGraphicsOverlay.graphics.removeAllObjects()
        tapLocationsGraphicsOverlay.graphics.removeAllObjects()
        tappedPointsAndRadius.removeAll()
        setStatus(message: "Buffers removed. Tap on the map to add buffers.")
    }
    
    @IBAction func distanceSliderValueChanged(_ sender: UISlider) {
        // Update the buffer radius with the slider value.
        bufferRadius.value = Double(sender.value)
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
            if let error = error {
                self?.presentAlert(error: error)
                self?.setStatus(message: "Fail to load basemap.")
            } else {
                self?.setStatus(message: "Tap on the map to add buffers.")
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
        // The spatial reference in this sample use US feet as unit.
        let radius = bufferRadius.converted(to: .feet).value
        // Ensure that the buffer radius in meters is a positive value.
        guard radius > 0 else { return }
        // Create and add graphic symbolizing the tap point.
        let pointGraphic = AGSGraphic(geometry: mapPoint, symbol: nil)
        tapLocationsGraphicsOverlay.graphics.add(pointGraphic)
        // Keep track of tapped points and their radius.
        tappedPointsAndRadius.append((point: mapPoint, radius: radius))
        setStatus(message: "Buffer center point added.")
    }
}
