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

class DisplayLocationViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let map = AGSMap(basemap: .imagery())
        mapView.map = map
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "DisplayLocationViewController",
            "DisplayLocationSettingsViewController",
            "OptionsTableViewController"
        ]
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? DisplayLocationSettingsViewController {
            controller.locationDisplay = mapView.locationDisplay
            
            controller.preferredContentSize = CGSize(width: 300, height: 150)
            navController.presentationController?.delegate = self
        }
    }
}

extension DisplayLocationViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
