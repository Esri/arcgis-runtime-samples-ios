//
// Copyright © 2018 Esri.
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

/// A view controller that manages the interface of the Identify KML Features
/// sample.
class IdentifyKMLFeaturesViewController: UIViewController {
    /// A KML layer with forecast data.
    let forecastLayer: AGSKMLLayer = {
        let url = URL(string: "https://www.wpc.ncep.noaa.gov/kml/noaa_chart/WPC_Day1_SigWx.kml")!
        let dataset = AGSKMLDataset(url: url)
        return AGSKMLLayer(kmlDataset: dataset)
    }()
    
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let map = AGSMap(basemap: .darkGrayCanvasVector())
        map.operationalLayers.add(forecastLayer)
        
        let center = AGSPoint(x: -48_885, y: 1_718_235, spatialReference: AGSSpatialReference(wkid: 5070))
        map.initialViewpoint = AGSViewpoint(center: center, scale: 50_000_000)
        
        mapView.map = map
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["IdentifyKMLFeaturesViewController"]
    }
    
    func showCallout(for placemark: AGSKMLPlacemark, at point: AGSPoint) {
        guard let data = placemark.balloonContent.data(using: .utf8) else { return }
        do {
            let attributedText = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
            let textView = UITextView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 50)))
            textView.isUserInteractionEnabled = false
            textView.attributedText = attributedText
            textView.backgroundColor = placemark.balloonBackgroundColor
            textView.sizeToFit()
            mapView.callout.customView = textView
            mapView.callout.show(at: point, screenOffset: .zero, rotateOffsetWithMap: false, animated: true)
        } catch {
            print("Error converting balloon content to attributed string: \(error)")
        }
    }
}

extension IdentifyKMLFeaturesViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        geoView.callout.dismiss()
        geoView.identifyLayer(forecastLayer, screenPoint: screenPoint, tolerance: 15, returnPopupsOnly: false) { [weak self] (result) in
            if let error = result.error {
                print("Error identifying layer: \(error)")
            } else if let placemarkIndex = result.geoElements.firstIndex(where: { $0 is AGSKMLPlacemark }) {
                let placemark = result.geoElements[placemarkIndex] as! AGSKMLPlacemark
                self?.showCallout(for: placemark, at: mapPoint)
            }
        }
    }
}
