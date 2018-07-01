//// Copyright 2018 Esri
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

class CutGeometryViewController: UIViewController {
    
    @IBOutlet weak var mapView: AGSMapView!
    
    let graphicsOverlay = AGSGraphicsOverlay()
    
    var lakeSuperiorPolygonGraphic: AGSGraphic = {
        
        // create an array of points that represents Lake Superior (polygon). Use the same spatial reference as the underlying base map
        let points = [
            AGSPoint(x: -10254374.668616, y: 5908345.076380, spatialReference: .webMercator()),
            AGSPoint(x: -10178382.525314, y: 5971402.386779, spatialReference: .webMercator()),
            AGSPoint(x: -10118558.923141, y: 6034459.697178, spatialReference: .webMercator()),
            AGSPoint(x: -9993252.729399,  y: 6093474.872295, spatialReference: .webMercator()),
            AGSPoint(x: -9882498.222673,  y: 6209888.368416, spatialReference: .webMercator()),
            AGSPoint(x: -9821057.766387,  y: 6274562.532928, spatialReference: .webMercator()),
            AGSPoint(x: -9690092.583250,  y: 6241417.023616, spatialReference: .webMercator()),
            AGSPoint(x: -9605207.742329,  y: 6206654.660191, spatialReference: .webMercator()),
            AGSPoint(x: -9564786.389509,  y: 6108834.986367, spatialReference: .webMercator()),
            AGSPoint(x: -9449989.747500,  y: 6095091.726408, spatialReference: .webMercator()),
            AGSPoint(x: -9462116.153346,  y: 6044160.821855, spatialReference: .webMercator()),
            AGSPoint(x: -9417652.665244,  y: 5985145.646738, spatialReference: .webMercator()),
            AGSPoint(x: -9438671.768711,  y: 5946341.148031, spatialReference: .webMercator()),
            AGSPoint(x: -9398250.415891,  y: 5922088.336339, spatialReference: .webMercator()),
            AGSPoint(x: -9419269.519357,  y: 5855797.317714, spatialReference: .webMercator()),
            AGSPoint(x: -9467775.142741,  y: 5858222.598884, spatialReference: .webMercator()),
            AGSPoint(x: -9462924.580403,  y: 5902686.086985, spatialReference: .webMercator()),
            AGSPoint(x: -9598740.325877,  y: 5884092.264688, spatialReference: .webMercator()),
            AGSPoint(x: -9643203.813979,  y: 5845287.765981, spatialReference: .webMercator()),
            AGSPoint(x: -9739406.633691,  y: 5879241.702350, spatialReference: .webMercator()),
            AGSPoint(x: -9783061.694736,  y: 5922896.763395, spatialReference: .webMercator()),
            AGSPoint(x: -9844502.151022,  y: 5936640.023354, spatialReference: .webMercator()),
            AGSPoint(x: -9773360.570059,  y: 6019099.583107, spatialReference: .webMercator()),
            AGSPoint(x: -9883306.649729,  y: 5968977.105610, spatialReference: .webMercator()),
            AGSPoint(x: -9957681.938918,  y: 5912387.211662, spatialReference: .webMercator()),
            AGSPoint(x: -10055501.612742, y: 5871965.858842, spatialReference: .webMercator()),
            AGSPoint(x: -10116942.069028, y: 5884092.264688, spatialReference: .webMercator()),
            AGSPoint(x: -10111283.079633, y: 5933406.315128, spatialReference: .webMercator()),
            AGSPoint(x: -10214761.742852, y: 5888134.399970, spatialReference: .webMercator()),
            AGSPoint(x: -10254374.668616, y: 5901877.659929, spatialReference: .webMercator())
        ]
        
        // create a polygon from the array of points
        let polygon = AGSPolygon(points: points)
        
        // create a blue border line symbol with a stroke weight of 4 for the Lake Superior polygon
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .blue, width: 4)
        
        // create a semi transparent blue fill symbol using the red border line symbol for the Lake Superior polygon
        let fillSymbol = AGSSimpleFillSymbol(style: .solid, color: #colorLiteral(red: 0, green: 0, blue: 1, alpha: 0.1), outline: lineSymbol)
        
        // create a graphic using the polyline and fill symbol for the border polyline
        let graphic = AGSGraphic(geometry: polygon, symbol: fillSymbol, attributes: nil)
        
        return graphic
    }()
    
    var borderPolylineGraphic: AGSGraphic = {
       
        // create an array of points that represents a cut line
        let points = [
            AGSPoint(x: -9981328.687124,  y: 6111053.281447, spatialReference: .webMercator()),
            AGSPoint(x: -9946518.044066,  y: 6102350.620682, spatialReference: .webMercator()),
            AGSPoint(x: -9872545.427566,  y: 6152390.920079, spatialReference: .webMercator()),
            AGSPoint(x: -9838822.617103,  y: 6157830.083057, spatialReference: .webMercator()),
            AGSPoint(x: -9446115.050097,  y: 5927209.572793, spatialReference: .webMercator()),
            AGSPoint(x: -9430885.393759,  y: 5876081.440801, spatialReference: .webMercator()),
            AGSPoint(x: -9415655.737420,  y: 5860851.784463, spatialReference: .webMercator())
        ]
        
        // create a polyline from the array of points
        let polyline = AGSPolyline(points: points)
        
        // create a red border line symbol with a stroke weight of 5
        let lineSymbol = AGSSimpleLineSymbol(style: .dot, color: .red, width: 5)
        
        // create a graphic using the polyline and line symbol for the border polyline
        let graphic = AGSGraphic(geometry: polyline, symbol: lineSymbol, attributes: nil)
        
        return graphic
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["CutGeometryViewController"]
        
        // instantiate map using basemap
        let map = AGSMap(basemap: .topographic())
        
        // assign map to the map view
        mapView.map = map
        
        // add lake superior polygon graphic and border polyline graphic to graphics overlay
        graphicsOverlay.graphics.addObjects(from: [lakeSuperiorPolygonGraphic, borderPolylineGraphic])

        // add graphics overlay to map view
        mapView.graphicsOverlays.add(graphicsOverlay)
        
        // set viewpoint to the extent of the Lake Superior polygon
        mapView.setViewpointGeometry(lakeSuperiorPolygonGraphic.geometry!, completion: nil)
    }
    
    @IBAction func cutGeometryWithPolyline(_ sender: Any) {
        
        // disable the cut button
        (sender as? UIBarButtonItem)?.isEnabled = false
        
        // cut the Lake Superior polygon using the border polyline
        guard let parts = AGSGeometryEngine.cut(lakeSuperiorPolygonGraphic.geometry!, withCutter: borderPolylineGraphic.geometry! as! AGSPolyline), parts.count >= 2 else {
            return
        }
        
        // create a null border line symbol for the newly cut Canada polygon
        let canadaLineSymbol = AGSSimpleLineSymbol(style: .null, color: .clear, width: 0)
        
        // create a green backward diagonal fill symbol for the newly cut Canada polygon
        let canadaFillSymbol = AGSSimpleFillSymbol(style: .backwardDiagonal, color: .green, outline: canadaLineSymbol)
        
        // create a Canada graphic using the polygon and line symbol
        let canadaSide = AGSGraphic(geometry: parts[0], symbol: canadaFillSymbol, attributes: nil)
        
        // create a null border line symbol for the newly cut USA polygon
        let usaLineSymbol = AGSSimpleLineSymbol(style: .null, color: .clear, width: 0)
        
        // create a yellow forward diagonal fill symbol for the newly cut USA polygon
        let usaFillSymbol = AGSSimpleFillSymbol(style: .forwardDiagonal, color: .yellow, outline: usaLineSymbol)
        
        // create a USA graphic using the polygon and line symbol
        let usaSide = AGSGraphic(geometry: parts[1], symbol: usaFillSymbol, attributes: nil)
        
        // add new graphics to graphics overlay
        graphicsOverlay.graphics.addObjects(from: [canadaSide, usaSide])
    }
}
