//
// Copyright 2016 Esri.
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

class VectorTileLayerViewController: UIViewController {
    @IBOutlet var mapView: AGSMapView!
    
    /// The model array containing the layer options.
    private let vectorTiledLayerItems: [(label: String, itemID: String)] = [
        ("Mid-Century", "7675d44bb1e4428aa2c30a9b68f97822"),
        ("Colored Pencil", "4cf7e1fb9f254dcda9c8fbadb15cf0f8"),
        ("Newspaper", "dfb04de5f3144a80bc3f9f336228d24a"),
        ("Nova", "75f4dfdff19e445395653121a95a85db"),
        ("Night", "86f556a2d1fd468181855a35e344567f")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "VectorTileLayerViewController",
            "OptionsTableViewController"
        ]
        
        /// The URL of the initial layer to display.
        let url = makeArcGISURL(itemID: vectorTiledLayerItems.first!.itemID)
        
        // create a vector tiled layer
        let vectorTileLayer = AGSArcGISVectorTiledLayer(url: url)
        // create a map and set the vector tiled layer as the basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: vectorTileLayer))
        
        // assign the map to the map view
        mapView.map = map

        // center on Miami, FL
        mapView.setViewpointCenter(AGSPoint(x: -80.18, y: 25.778135, spatialReference: .wgs84()), scale: 150000)
    }
    
    private func makeArcGISURL(itemID: String) -> URL {
        var urlComponents = URLComponents(string: "https://www.arcgis.com/home/item.html")!
        urlComponents.queryItems = [URLQueryItem(name: "id", value: itemID)]
        return urlComponents.url!
    }

    @IBAction func changeVectorTiledLayer(_ sender: UIBarButtonItem) {
        guard let layer = mapView.map?.basemap.baseLayers.firstObject as? AGSArcGISVectorTiledLayer,
            let selectedItemID = layer.item?.itemID,
            // get the index of the layer currently shown in the map
            let selectedIndex = vectorTiledLayerItems.firstIndex(where: { $0.itemID == selectedItemID }) else {
            return
        }
        
        /// The labels for the layer options
        let layerLabels = vectorTiledLayerItems.map { $0.label }
        
        /// A view controller allowing the user to select the layer to show.
        let controller = OptionsTableViewController(labels: layerLabels, selectedIndex: selectedIndex) { [weak self] (newIndex) in
            guard let self = self else {
                return
            }
            
            // get the layer ID for the index
            let itemID = self.vectorTiledLayerItems[newIndex].itemID
            // get the url for the layer ID
            let url = self.makeArcGISURL(itemID: itemID)
            // create the new vector tiled layer using the url
            let vectorTileLayer = AGSArcGISVectorTiledLayer(url: url)
            // change the basemap to the new layer
            self.mapView.map?.basemap = AGSBasemap(baseLayer: vectorTileLayer)
        }
        
        // configure the options controller as a popover
        controller.modalPresentationStyle = .popover
        controller.presentationController?.delegate = self
        controller.preferredContentSize = CGSize(width: 300, height: 220)
        controller.popoverPresentationController?.barButtonItem = sender
        controller.popoverPresentationController?.passthroughViews?.append(mapView)
        
        // show the popover
        present(controller, animated: true)
    }
}

extension VectorTileLayerViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // show presented controller as popovers even on small displays
        return .none
    }
}
