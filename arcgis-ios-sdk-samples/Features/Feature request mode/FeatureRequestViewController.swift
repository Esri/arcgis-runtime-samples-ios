// Copyright 2021 Esri.
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

class FeatureRequestModeViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var featureRequestModeButton: UIBarButtonItem!
    
    @IBAction func modeButonTapped(_ button: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Choose a feature request mode.",
            message: nil,
            preferredStyle: .actionSheet
        )
        filterBarrierCategories.forEach { category in
            let action = UIAlertAction(title: category.name, style: .default) { [self] _ in
                selectedCategory = category
                setStatus(message: "\(category.name) selected.")
                traceResetBarButtonItem.isEnabled = true
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = featureRequestModeButton
        present(alertController, animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FeatureRequestModeViewController"]
    }
}
