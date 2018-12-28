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

class VectorTileCustomStyleVC: UIViewController, VectorStylesVCDelegate {
    @IBOutlet var mapView: AGSMapView!
    
    private var itemIDs = ["1349bfa0ed08485d8a92c442a3850b06",
                           "bd8ac41667014d98b933e97713ba8377",
                           "02f85ec376084c508b9c8e5a311724fa",
                           "1bf0cc4a4380468fbbff107e100f65a5"]
    private var shownItemID: String? {
        return ((mapView.map?.basemap.baseLayers.firstObject as? AGSArcGISVectorTiledLayer)?.item as? AGSPortalItem)?.itemID
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["VectorTileCustomStyleVC", "VectorStylesViewController"]
        
        //initialize map
        let map = AGSMap()

        //initial viewpoint
        let centerPoint = AGSPoint(x: 1990591.559979, y: 794036.007991, spatialReference: .webMercator())
        map.initialViewpoint = AGSViewpoint(center: centerPoint, scale: 88659253.829259947)
        
        //assign map to map view
        mapView.map = map
        
        //show the default vector tiled layer
        showSelectedItem(itemIDs.first!)
    }
    
    private func showSelectedItem(_ itemID: String) {
        let vectorTiledLayerURL = URL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=\(itemID)")!
        let vectorTiledLayer = AGSArcGISVectorTiledLayer(url: vectorTiledLayerURL)
        mapView.map?.basemap = AGSBasemap(baseLayer: vectorTiledLayer)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? VectorStylesViewController {
            controller.delegate = self
            controller.itemIDs = itemIDs
            controller.selectedItemID = shownItemID
            controller.presentationController?.delegate = self
            controller.preferredContentSize = {
                let height: CGFloat
                if traitCollection.horizontalSizeClass == .regular,
                    traitCollection.verticalSizeClass == .regular {
                    height = 200
                } else {
                    height = 150
                }
                return CGSize(width: 375, height: height)
            }()
        }
    }
    
    // MARK: - VectorStylesVCDelegate
    
    func vectorStylesViewController(_ vectorStylesViewController: VectorStylesViewController, didSelectItemWithID itemID: String) {
        //show newly selected vector layer
        showSelectedItem(itemID)
    }
}

extension VectorTileCustomStyleVC: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
