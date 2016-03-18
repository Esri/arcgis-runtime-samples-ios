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

class LocalTiledLayerViewController: UIViewController, TilePackagesListVCDelegate {
    
    @IBOutlet var mapView: AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["LocalTiledLayerViewController"]
        
        let path = NSBundle.mainBundle().pathForResource("Campus", ofType: "tpk")!
        let tileCache = AGSTileCache(path: path)
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: tileCache)
        
        let map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        
        self.mapView.map = map
        
        tileCache.loadWithCompletion { (error: NSError?) -> Void in
            print(tileCache.source)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TilePackagesListSegue" {
            let controller = segue.destinationViewController as! TilePackagesListViewController
            controller.delegate = self
        }
    }
    
    //MARK: - TilePackagesListVCDelegate
    
    func tilePackagesListViewController(tilePackagesListViewController: TilePackagesListViewController, didSelectTPKWithPath path: String) {
        
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(path: path))
        let map = AGSMap(basemap: AGSBasemap(baseLayer: localTiledLayer))
        self.mapView.map = map
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
}
