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
    /// A label to display status messages.
    @IBOutlet weak var statusLabel: UILabel!
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.graphicsOverlays.addObjects(from: [boundaryGraphicsOverlay, bufferGraphicsOverlay, tapLocationsGraphicsOverlay])
            mapView.touchDelegate = self
        }
    }
    let statePlaneNorthCentralTexas = AGSSpatialReference(wkid: 32038)!
    /// An image layer
    let mapImageLayer = AGSArcGISMapImageLayer(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/USA/MapServer")!)
    /// An overlay
    let bufferGraphicsOverlay = AGSGraphicsOverlay()
    /// An overlay for displaying the location of the tap point with red circle symbol.
    let tapLocationsGraphicsOverlay = AGSGraphicsOverlay()
    /// An overlay
    let boundaryGraphicsOverlay = AGSGraphicsOverlay()
    /// An array of tapped points and buffer radius paris.
    var tappedPointsAndRadius = [(point: AGSPoint, radius: Double)]()
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
    
    var isUnion = false
    var bufferRadius: Measurement<UnitLength> = Measurement(value: 50, unit: .miles)
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(spatialReference: statePlaneNorthCentralTexas)
        map.basemap.baseLayers.add(mapImageLayer)
        map.initialViewpoint = AGSViewpoint(targetExtent: boundaryPolygon.extent)
        return map
    }
    
    func configureGraphicsOverlays() {
        let circleSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .red, size: 10)
        tapLocationsGraphicsOverlay.renderer = AGSSimpleRenderer(symbol: circleSymbol)
        
        let lineSymbol = AGSSimpleLineSymbol(style: .dash, color: .red, width: 5)
        let boundaryGraphic = AGSGraphic(geometry: boundaryPolygon, symbol: lineSymbol)
        boundaryGraphicsOverlay.graphics.add(boundaryGraphic)
        
        let bufferPolygonOutlineSymbol = AGSSimpleLineSymbol(style: .solid, color: .primaryBlue, width: 3)
        let bufferPolygonFillSymbol = AGSSimpleFillSymbol(style: .solid, color: .cyan, outline: bufferPolygonOutlineSymbol)
        bufferGraphicsOverlay.renderer = AGSSimpleRenderer(symbol: bufferPolygonFillSymbol)
    }
    
    @IBAction func createButtonTapped(_ sender: UIBarButtonItem) {
        if let bufferPolygon = AGSGeometryEngine.bufferGeometries(tappedPointsAndRadius.map { $0.point }, distances: tappedPointsAndRadius.map { NSNumber(value: $0.radius) }, unionResults: isUnion) {
            let graphics: [AGSGraphic] = bufferPolygon.map {
                let graphic = AGSGraphic(geometry: $0, symbol: nil)
                graphic.zIndex = 0
                return graphic
            }
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
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? BufferListSettingsViewController {
            // Popover settings and preferred content size.
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 128)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "BufferListViewController",
            "BufferListSettingsViewController"
        ]
        // Load the map image layer.
        mapImageLayer.load { [weak self] (error) in
            if let error = error {
                self?.presentAlert(error: error)
                self?.setStatus(message: "Fail to load basemap.")
            } else {
                self?.setStatus(message: "Tap on the map to add buffers.")
            }
        }
        configureGraphicsOverlays()
    }
}

extension BufferListViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Only proceed when the tapped point is within the boundary.
        guard AGSGeometryEngine.geometry(boundaryPolygon, contains: mapPoint) else {
            return
        }
        // Ensure that the buffer radius in meters is a positive value.
        let spatialReferenceUnit = statePlaneNorthCentralTexas.unit
        print(spatialReferenceUnit.abbreviation)
        let radius = bufferRadius.converted(to: .meters).value
        guard radius > 0 else {
            return
        }
        // Create and add graphic symbolizing the tap point.
        let pointGraphic = AGSGraphic(geometry: mapPoint, symbol: nil)
        tapLocationsGraphicsOverlay.graphics.add(pointGraphic)
        // Keep track of tapped points and their radius.
        tappedPointsAndRadius.append((point: mapPoint, radius: radius))
        setStatus(message: "Point added.")
    }
}

extension BufferListViewController: BufferListSettingsViewControllerDelegate {
    func bufferListSettingsViewController(_ bufferListSettingsViewController: BufferListSettingsViewController, bufferDistanceChangedTo bufferDistance: Measurement<UnitLength>, areBuffersUnioned: Bool) {
        bufferRadius = bufferDistance
        isUnion = areBuffersUnioned
    }
}

extension BufferListViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // For popover or non modal presentation.
        return .none
    }
}
