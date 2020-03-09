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
            mapView.sketchEditor = sketchEditor
        }
    }
    
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .darkGrayCanvasVector())
        return map
    }
    
    var sketchEditor = AGSSketchEditor()
    var sketchCreationModeComboBox: AGSSketchCreationMode!
    let kmlDocument = AGSKMLDocument()
    let spatialRef = AGSSpatialReference(wkid: 4326)!
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
    
    
    func makeKMLStyleWithPointStyle() -> AGSKMLStyle {
        let iconURL = URL(string: "https://static.arcgis.com/images/Symbols/Shapes/BlueStarLargeB.png")!
        let icon = AGSKMLIcon(url: iconURL)
        let iconStyle = AGSKMLIconStyle(icon: icon, scale: 1.0)
        
        let kmlStyle = AGSKMLStyle()
        kmlStyle.iconStyle = iconStyle
        return kmlStyle
    }
    
    func makeKMLStyleWithLineStyle() -> AGSKMLStyle {
        let lineStyle = AGSKMLLineStyle(color: .red, width: 2.0)
        let kmlStyle = AGSKMLStyle()
        kmlStyle.lineStyle = lineStyle
        return kmlStyle
    }
    
    func makeKMLStyleWithPolygonStyle() -> AGSKMLStyle {
        let polygonStyle = AGSKMLPolygonStyle(color: .yellow)
        let kmlStyle = AGSKMLStyle()
        kmlStyle.polygonStyle = polygonStyle
        return kmlStyle
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
}
