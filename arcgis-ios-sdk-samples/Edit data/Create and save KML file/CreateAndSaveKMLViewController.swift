//
// Copyright © 2020 Esri.
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
//

import UIKit
import ArcGIS

class CreateAndSaveKMLViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            let sketchEditor = AGSSketchEditor()
            mapView.sketchEditor = sketchEditor
            let sketch = mapView.sketchEditor
            let point = AGSPoint(x: 44.00, y: 22.00, spatialReference: .wgs84())
            sketch?.start(with: point)
        }
    }
    
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .darkGrayCanvasVector())
        let kmlDataset = AGSKMLDataset(rootNode: kmlDocument)
        map.operationalLayers.add(AGSKMLLayer(kmlDataset: kmlDataset))
        return map
    }

    var color: UIColor!
    let sketchStyle = AGSSketchStyle()
    var sketchCreationMode: AGSSketchCreationMode!
    let kmlDocument = AGSKMLDocument()
    let spatialRef = AGSSpatialReference.wgs84()
    var kmlStyle = AGSKMLStyle()
//    func makePoints() {
//        point = AGSPoint(x: -117.195800, y: 34.056295, spatialReference: self.spatialRef)
//    }
//    let point = AGSPoint(x: -117.195800, y: 34.056295, spatialReference: self.spatialRef)
//        let polylinePoints = [
//            AGSPoint(x: -119.992, y: 41.989, spatialReference: spatialRef),
//            AGSPoint(x: -119.994, y: 38.994, spatialReference: spatialRef),
//            AGSPoint(x: -114.620, y: 35.0, spatialReference: spatialRef)
//        ]
//        let polygonPoints = [
//            AGSPoint(x: -109.048, y: 40.998, spatialReference: spatialRef),
//            AGSPoint(x: -102.047, y: 40.998, spatialReference: spatialRef),
//            AGSPoint(x: -102.037, y: 36.989, spatialReference: spatialRef),
//            AGSPoint(x: -109.048, y: 36.998, spatialReference: spatialRef)
//        ]
//        let polyline = AGSPolyline(points: polylinePoints)
//        let polygon = AGSPolygon(points: polygonPoints)
//        let envelope = AGSEnvelope(xMin: -123.0, yMin: 33.5, xMax: -101.0, yMax: 42.0, spatialReference: spatialRef)
    
    func addKMLPlaceMark(view: UIView) {
        guard let sketchEditor = mapView.sketchEditor else { return }
        if sketchEditor.isSketchValid {
            var sketchGeometry = sketchEditor.geometry!
            var projectedGeometry = AGSGeometryEngine.projectGeometry(sketchGeometry, to: spatialRef)
            sketchEditor.stop()
            
//            let currentKMLPlacemark = AGSKMLPlacemark(geometry: projectedGeometry)
        }
    }
 
//    func addGraphics() {
//        addToKMLDocument(geometry: point, kmlStyle: makeKMLStyleWithPointStyle())
//        addToKMLDocument(geometry: polyline, kmlStyle: makeKMLStyleWithLineStyle())
//        addToKMLDocument(geometry: polygon, kmlStyle: makeKMLStyleWithPolygonStyle())
//        mapView.map?.operationalLayers.add(AGSKMLLayer)
//    }
    
    func addToKMLDocument(geometry: AGSGeometry, kmlStyle: AGSKMLStyle) {
        let temp = AGSKMLAltitudeMode(rawValue: 6)!
        let kmlGeometry = AGSKMLGeometry(geometry: geometry, altitudeMode: temp)!
        let placemark = AGSKMLPlacemark(geometry: kmlGeometry)
        placemark.style = kmlStyle
        kmlDocument.addChildNode(placemark)
    }
    
    private func startSketch(sketchCreationMode: AGSSketchCreationMode) {
        mapView.sketchEditor?.stop()
        mapView.sketchEditor?.start(with: sketchCreationMode)
    }
    
    func makeKMLStyleWithPointStyle(icon: AGSKMLIcon, color: UIColor) -> AGSKMLStyle {
        let iconStyle = AGSKMLIconStyle(icon: icon, scale: 1.0)
        let kmlStyle = AGSKMLStyle()
        kmlStyle.iconStyle = iconStyle
        return kmlStyle
    }
    
    func makeKMLStyleWithLineStyle(color: UIColor) -> AGSKMLStyle {
        let kmlStyle = AGSKMLStyle()
        kmlStyle.lineStyle = AGSKMLLineStyle(color: color, width: 2.0)
        return kmlStyle
    }
    
    func makeKMLStyleWithPolygonStyle(color: UIColor) -> AGSKMLStyle {
        let kmlStyle = AGSKMLStyle()
        kmlStyle.polygonStyle = AGSKMLPolygonStyle(color: color)
        return kmlStyle
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let navigationController = segue.destination as? UINavigationController,
            let settingsViewController = navigationController.topViewController as? CreateAndSaveKMLSettingsViewController {
            color = settingsViewController.color
            settingsViewController.kmlStyle = kmlStyle
            settingsViewController.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "CreateAndSaveKMLViewController",
            "CreateAndSaveKMLSettingsViewController"
        ]
    }
}

// MARK: - AGSGeoViewTouchDelegate
extension CreateAndSaveKMLViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        addToKMLDocument(geometry: mapPoint, kmlStyle: kmlStyle)
        
    }
}

extension CreateAndSaveKMLViewController: CreateAndSaveKMLSettingsViewControllerDelegate {
    func createAndSaveKMLSettingsViewController(_ createAndSaveKMLSettingsViewController: CreateAndSaveKMLSettingsViewController, feature: String, icon: AGSKMLIcon?, color: UIColor) {
        switch feature {
        case "point":
            guard let icon = icon else { return }
            kmlStyle = makeKMLStyleWithPointStyle(icon: icon, color: color)
        case "polyline":
            kmlStyle = makeKMLStyleWithLineStyle(color: color)
        case "polygon":
            kmlStyle = makeKMLStyleWithPolygonStyle(color: color)
        default:
            print("default statement to replace with something")
        }
    }
    
    func createAndSaveKMLSettingsViewControllerDidFinish(_ controller: CreateAndSaveKMLSettingsViewController) {
        dismiss(animated: true)
    }
}
