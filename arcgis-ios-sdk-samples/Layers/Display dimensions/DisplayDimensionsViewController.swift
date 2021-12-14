// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class DisplayDimensionsViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            // Set the viewpoint to the southwest of Edinburgh, UK.
            mapView.setViewpointCenter(AGSPointMakeWGS84(55.908, -3.305))
            loadMobileMapPackage()
        }
    }
    @IBOutlet var settingsBarButtonItem: UIBarButtonItem!
    
    // MARK: Properties
    
    /// The dimension layer. Will be `nil` until the mmpk has finished loading.
    var dimensionLayer: AGSDimensionLayer!
    
    // MARK: Methods
    
    /// Initiates loading of the mobile map package.
    func loadMobileMapPackage() {
        // The mobile map package used by this sample.
        let mobileMapPackage = AGSMobileMapPackage(fileURL: Bundle.main.url(forResource: "Edinburgh_Pylon_Dimensions", withExtension: "mmpk")!)
        mobileMapPackage.load { [weak self] error in
            guard let self = self else { return }
            let result: Result<AGSMap, Error>
            if let map = mobileMapPackage.maps.first {
                result = .success(map)
            } else if let error = error {
                result = .failure(error)
            } else {
                fatalError("MMPK doesn't contain a map.")
            }
            self.mobileMapPackageDidLoad(with: result)
        }
    }
    
    /// Called in response to the mobile map package load operation completing.
    /// - Parameter result: The result of the load operation.
    func mobileMapPackageDidLoad(with result: Result<AGSMap, Error>) {
        switch result {
        case .success(let map):
            // Set a minScale to maintain dimension readability.
            map.minScale = 4e4
            mapView.map = map
            // Get the dimension layer.
            if let layer = map.operationalLayers.first(where: { $0 is AGSDimensionLayer }) as? AGSDimensionLayer {
                dimensionLayer = layer
                settingsBarButtonItem.isEnabled = true
            }
        case .failure(let error):
            presentAlert(error: error)
        }
    }
    
    // MARK: UIViewController
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let settingsViewController = segue.destination as? DisplayDimensionsSettingsViewController {
            settingsViewController.dimensionLayer = dimensionLayer
            settingsViewController.popoverPresentationController?.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DisplayDimensionsViewController"]
    }
}

extension DisplayDimensionsViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
