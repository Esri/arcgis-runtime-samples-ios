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

import UIKit
import ArcGIS

class LocalTiledLayerViewController: UIViewController, TilePackagesListViewControllerDelegate {
    @IBOutlet weak var mapView: AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["LocalTiledLayerViewController", "TilePackagesListViewController"]
        
        //create a tiled layer using one of the tile packages
        let tileCache = AGSTileCache(name: "SanFrancisco")
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
        
        //instantiate a map, use the tiled layer as the basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        //assign the map to the map view
        self.mapView.map = map
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? TilePackagesListViewController {
            controller.delegate = self
        }
    }
    
    // MARK: - TilePackagesListViewControllerDelegate
    
    //called when a selection is made in the tile packages list
    func tilePackagesListViewController(_ tilePackagesListViewController: TilePackagesListViewController, didSelectTilePackageAt url: URL) {
        //create a new map with selected tile package as the basemap
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(fileURL: url))
        let map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        self.mapView.map = map
        
        _ = self.navigationController?.popViewController(animated: true)
    }
}
