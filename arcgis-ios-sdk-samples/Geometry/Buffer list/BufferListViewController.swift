// Copyright 2020 Esri
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

class BufferListViewController: UIViewController {
    @IBOutlet weak var statusLabel: UILabel!
    
    // The map view managed by the view controller.
    @IBOutlet weak var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
//            mapView.graphicsOverlays.add(graphicsOverlay)
            mapView.touchDelegate = self
        }
    }
    
    var bufferGraphicsOverlay: AGSGraphicsOverlay!
    var isUnion = false
    var distance: Measurement<UnitLength> = Measurement(value: 500, unit: .miles)
    
    /// Creates a map.
    ///
    /// - Returns: A new `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .topographic())
        return map
    }
    
    @IBAction func createButtonTapped(_ sender: UIBarButtonItem) {
        
    }
    
    @IBAction func clearButtonTapped(_ sender: UIBarButtonItem) {
        bufferGraphicsOverlay.graphics.removeAllObjects()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? BufferListSettingsViewController {
            // Popover settings.
            controller.presentationController?.delegate = self
            // Preferred content size.
            if traitCollection.horizontalSizeClass == .regular, traitCollection.verticalSizeClass == .regular {
                controller.preferredContentSize = CGSize(width: 300, height: 380)
            } else {
                controller.preferredContentSize = CGSize(width: 300, height: 250)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "BufferListViewController",
            "BufferListSettingsViewController"
        ]
    }
}

extension BufferListViewController: AGSGeoViewTouchDelegate {
    
}

extension BufferListViewController: BufferListSettingsViewControllerDelegate {
    func bufferOptionsViewController(_ bufferOptionsViewController: BufferListSettingsViewController, bufferDistanceChangedTo bufferDistance: Measurement<UnitLength>, areBuffersUnioned: Bool) {
        distance = bufferDistance
        isUnion = areBuffersUnioned
    }
}

extension BufferListViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // For popover or non modal presentation.
        return .none
    }
}
