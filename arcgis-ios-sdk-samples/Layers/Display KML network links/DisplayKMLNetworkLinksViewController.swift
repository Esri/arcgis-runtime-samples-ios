// Copyright 2018 Esri.
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

class DisplayKMLNetworkLinksViewController: UIViewController {
    
    @IBOutlet weak var sceneView: AGSSceneView!
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayKMLNetworkLinksViewController"]
        
        // instantiate a scene using labeled imagery
        let scene = AGSScene(basemapType: .imageryWithLabels)
        // set the view's scene
        sceneView.scene = scene
        
        // create and set a viewpoint centered on the data coverage
        let viewpoint = AGSViewpoint(center: AGSPoint(x: 8.150526, y: 50.472421, spatialReference: .wgs84()), scale: 10000000)
        sceneView.setViewpoint(viewpoint)
        
        // set the initial text
        textView.text = "Network Link Messages:\n\n"
        
        /// The URL of a KML file with network links
        let datasetURL = URL(string: "https://www.arcgis.com/sharing/rest/content/items/600748d4464442288f6db8a4ba27dc95/data")!
        /// The KML dataset with network links
        let kmlDataset = AGSKMLDataset(url: datasetURL)
        
        // register to receive the network link messages
        kmlDataset.networkLinkMessageHandler = {[weak self] (_, message) in
            // run UI updates on the main thread
            DispatchQueue.main.async {
                 self?.textView.text += "\(message)\n\n"
            }
        }
        
        /// The layer used to display the KML data
        let kmlLayer = AGSKMLLayer(kmlDataset: kmlDataset)
        // add the layer to the scene
        scene.operationalLayers.add(kmlLayer)
    }
    
}
