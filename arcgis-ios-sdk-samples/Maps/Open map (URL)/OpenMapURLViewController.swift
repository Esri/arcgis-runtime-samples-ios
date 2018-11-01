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

class OpenMapURLViewController: UIViewController {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    /// The portal item ID of the map now shown in the map view.
    var displayedMapID: String? {
        return (mapView.map?.item as? AGSPortalItem)?.itemID
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// The URL of the first map to show.
        let initialMapURL = URL(string: "https://www.arcgis.com/home/item.html?id=2d6fa24b357d427f9c737774e7b0f977")!

        // create the map for the url and add it to the map view
        showMap(at: initialMapURL)

        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "OpenMapURLViewController",
            "OpenMapURLSettingsViewController"
        ]
    }
    
    /// Creates a map for the url and adds it to the map view.
    private func showMap(at url: URL){
        // create a map object from the URL
        let map = AGSMap(url: url)
        // add the map to the map view
        mapView.map = map
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? OpenMapURLSettingsViewController {
            controller.initialSelectedID = displayedMapID
            controller.onChange = {[weak self] (url) in
                self?.showMap(at: url)
            }
            controller.preferredContentSize = CGSize(width: 300, height: 250)
            controller.presentationController?.delegate = self
        }
    }

}

extension OpenMapURLViewController: UIAdaptivePresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
}
