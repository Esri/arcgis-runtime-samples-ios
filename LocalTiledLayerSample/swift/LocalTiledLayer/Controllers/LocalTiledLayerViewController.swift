/*
Copyright 2015 Esri

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import UIKit
import ArcGIS

class LocalTiledLayerViewController: UIViewController {

    @IBOutlet weak var mapView:AGSMapView!
    
    var tilePackage:String!
    var localTiledLayer:AGSLocalTiledLayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Remove the file extension (if it exists) from the name
        let fileExtension = (self.tilePackage as NSString).pathExtension
        if (!fileExtension.isEmpty) {
            self.tilePackage = (self.tilePackage as NSString).stringByDeletingPathExtension
        }
        
        //Initialze the layer
        self.localTiledLayer = AGSLocalTiledLayer(name: self.tilePackage)
        
        
        //If layer was initialized properly, add to the map
        if self.localTiledLayer != nil && self.localTiledLayer.error == nil {
            self.mapView.addMapLayer(self.localTiledLayer, withName:"Local Tiled Layer")
        }
        else {
            UIAlertView(title: "Could not load tile package", message:self.localTiledLayer.error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
