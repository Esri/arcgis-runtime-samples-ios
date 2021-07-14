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

class SwitchBasemapViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView! {
        didSet {
            // Initialize the map with the first basemap.
            mapView.map = AGSMap(basemap: basemapInfoArray.first!.basemap)
        }
    }
    
    /// The basemap options plus labels.
    private let basemapInfoArray: [(basemap: AGSBasemap, label: String)] = [
        (.init(style: .arcGISDarkGrayBase), "Dark Gray Canvas"),
        (.init(style: .arcGISImageryStandard), "Imagery"),
        (.init(style: .arcGISImagery), "Imagery w/ Labels"),
        (.init(style: .arcGISLightGrayBase), "Light Gray Canvas"),
        (.init(style: .arcGISNavigation), "Navigation"),
        (.init(style: .arcGISNavigationNight), "Navigation Night"),
        (.init(style: .arcGISOceans), "Oceans"),
        (.init(style: .osmStreets), "OpenStreetMap"),
        (.init(style: .arcGISStreets), "Streets"),
        (.init(style: .arcGISStreetsNight), "Streets Night"),
        (.init(style: .osmStreetsRelief), "Streets w/ Relief"),
        (.init(style: .arcGISTerrain), "Terrain w/ Labels"),
        (.init(style: .arcGISTopographic), "Topographic"),
        (.init(style: .arcGISHillshadeLight), "Hillshade Light"),
        (.init(style: .arcGISHillshadeDark), "Hillshade Dark"),
        (.init(style: .arcGISNova), "Nova")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "SwitchBasemapViewController",
            "OptionsTableViewController"
        ]
    }

    @IBAction func changeBasemapAction(_ sender: UIBarButtonItem) {
        guard let basemap = mapView.map?.basemap,
            // Get the index of the basemap currently shown in the map.
            let selectedIndex = basemapInfoArray.firstIndex(where: { $0.basemap == basemap }) else {
            return
        }
        
        let basemapLabels = basemapInfoArray.map { $0.label }
        
        /// A view controller allowing the user to select the basemap to show.
        let controller = OptionsTableViewController(labels: basemapLabels, selectedIndex: selectedIndex) { [weak self] (newIndex) in
            if let self = self {
                // Update the map with the selected basemap.
                self.mapView?.map?.basemap = self.basemapInfoArray[newIndex!].basemap
            }
        }
        
        // Configure the options controller as a popover.
        controller.modalPresentationStyle = .popover
        controller.presentationController?.delegate = self
        controller.preferredContentSize = CGSize(width: 300, height: 300)
        controller.popoverPresentationController?.barButtonItem = sender
        controller.popoverPresentationController?.passthroughViews?.append(mapView)
        
        // Show the popover.
        present(controller, animated: true)
    }
}

extension SwitchBasemapViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // Show presented controller as popovers even on small displays.
        return .none
    }
}
