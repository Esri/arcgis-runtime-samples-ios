//
// Copyright © 2019 Esri.
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

/// A view controller that manages the interface of the Read Symbols from a
/// Mobile Style sample.
class ReadSymbolsFromMobileStyleViewController: UIViewController {
    /// The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemap: .topographic())
            mapView.graphicsOverlays.add(AGSGraphicsOverlay())
            mapView.touchDelegate = self
        }
    }
    
    /// The view controller that manages the symbol to be added when the map
    /// view is tapped.
    let symbolViewController = UIStoryboard(name: "ReadSymbolsFromMobileStyle", bundle: nil).instantiateViewController(withIdentifier: "SymbolViewController") as! ReadSymbolsFromMobileStyleSymbolViewController
    
    /// Shows the symbol view controller.
    @IBAction func showSymbol() {
        let navigationController = UINavigationController(rootViewController: symbolViewController)
        navigationController.modalPresentationStyle = .formSheet
        present(navigationController, animated: true)
    }
    
    /// Removes all the graphics from the map view.
    @IBAction func removeAllGraphics() {
        (mapView.graphicsOverlays.firstObject as? AGSGraphicsOverlay)?.graphics.removeAllObjects()
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "ReadSymbolsFromMobileStyleViewController",
            "ReadSymbolsFromMobileStyleSymbolViewController",
            "ReadSymbolsFromMobileStyleSymbolSettingsViewController"
        ]
    }
}

extension ReadSymbolsFromMobileStyleViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        guard let symbol = symbolViewController.symbol else { return }
        let graphic = AGSGraphic(geometry: mapPoint, symbol: symbol)
        (mapView.graphicsOverlays.firstObject as? AGSGraphicsOverlay)?.graphics.add(graphic)
    }
}
