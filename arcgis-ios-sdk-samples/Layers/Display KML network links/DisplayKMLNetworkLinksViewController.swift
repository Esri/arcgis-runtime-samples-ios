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
    
    /// The controller shown in a popover after tapping "View Messages"
    private weak var messageViewController: KMLNetworkMessagesViewController?
    private var messageText = "Network Link Messages:\n\n" {
        didSet {
            updatePopoverForMessage()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplayKMLNetworkLinksViewController"]
        
        // instantiate a scene using labeled imagery
        let scene = AGSScene(basemapType: .imageryWithLabels)
        // set the view's scene
        sceneView.scene = scene
        
        // create and set a viewpoint centered on the data coverage
        let viewpoint = AGSViewpoint(center: AGSPoint(x: 8.150526, y: 50.472421, spatialReference: .wgs84()), scale: 10000000)
        sceneView.setViewpoint(viewpoint)
        
        /// The URL of a KML file with network links
        let datasetURL = URL(string: "https://www.arcgis.com/sharing/rest/content/items/600748d4464442288f6db8a4ba27dc95/data")!
        /// The KML dataset with network links
        let kmlDataset = AGSKMLDataset(url: datasetURL)
        
        // register to receive the network link messages
        kmlDataset.networkLinkMessageHandler = { [weak self] (_, message) in
            // run UI updates on the main thread
            DispatchQueue.main.async {
                // append the message to the prior messages
                self?.messageText += "\(message)\n\n"
            }
        }
        
        /// The layer used to display the KML data
        let kmlLayer = AGSKMLLayer(kmlDataset: kmlDataset)
        // add the layer to the scene
        scene.operationalLayers.add(kmlLayer)
    }
    
    private func updatePopoverForMessage() {
        // updates the text shown in the text view with the message text
        messageViewController?.textView?.text = messageText
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // The popovover segue is triggered via storyboard connections, so set it up here.
        if let controller = segue.destination as? KMLNetworkMessagesViewController {
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 300)
            // load the view so the text view can be accessed now
            controller.loadViewIfNeeded()
            // retain a reference to the controller so the text view can be updated from `updatePopoverForMessage()`
            messageViewController = controller
            // set the initial message
            updatePopoverForMessage()
        }
    }
}

extension DisplayKMLNetworkLinksViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // show as this as a popover even on small displays
        return .none
    }
}

class KMLNetworkMessagesViewController: UIViewController {
    @IBOutlet var textView: UITextView!
}
