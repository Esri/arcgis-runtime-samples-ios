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

class CustomDictionaryStyleViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            mapView.setViewpoint(
                AGSViewpoint(
                    latitude: 34.0574,
                    longitude: -117.1963,
                    scale: 1e4
                )
            )
        }
    }
    /// The segmented control to toggle between style file and web style.
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    // MARK: Instance properties
    
    /// A feature layer showing a subset of restaurants in Redlands, CA.
    let featureLayer: AGSFeatureLayer = {
        // Create restaurants feature table from the feature service URL.
        let restaurantFeatureTable = AGSServiceFeatureTable(
            url: URL(string: "https://services2.arcgis.com/ZQgQTuoyBrtmoGdP/arcgis/rest/services/Redlands_Restaurants/FeatureServer/0")!
        )
        // Create the restaurants layer.
        return AGSFeatureLayer(featureTable: restaurantFeatureTable)
    }()
    
    /// A dictionary renderer created from a custom symbol style dictionary file
    /// (.stylx) on local disk.
    let dictionaryRendererFromStyleFile: AGSDictionaryRenderer = {
        // The URL to the symbol style dictionary from shared resources.
        let restaurantStyleURL = Bundle.main.url(forResource: "Restaurant", withExtension: "stylx")!
        // Create the dictionary renderer from the style file.
        let restaurantStyle = AGSDictionarySymbolStyle(url: restaurantStyleURL)
        return AGSDictionaryRenderer(dictionarySymbolStyle: restaurantStyle)
    }()
    
    /// A dictionary renderer created from a custom symbol style hosted on
    /// ArcGIS Online.
    let dictionaryRendererFromWebStyle: AGSDictionaryRenderer = {
        // The restaurant web style.
        let item = AGSPortalItem(
            portal: .arcGISOnline(withLoginRequired: false),
            itemID: "adee951477014ec68d7cf0ea0579c800"
        )
        // Create the dictionary renderer from the web style.
        let restaurantStyle = AGSDictionarySymbolStyle(portalItem: item)
        // Map the input fields in the feature layer to the
        // dictionary symbol style's expected fields for symbols.
        return AGSDictionaryRenderer(dictionarySymbolStyle: restaurantStyle, symbologyFieldOverrides: ["healthgrade": "Inspection"], textFieldOverrides: [:])
    }()
    
    // MARK: Methods
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        let isStyleFile = sender.selectedSegmentIndex == 0
        // Apply the dictionary renderer to the feature layer.
        featureLayer.renderer = isStyleFile ? dictionaryRendererFromStyleFile : dictionaryRendererFromWebStyle
    }
    
    func setupUI() {
        mapView.map?.operationalLayers.add(featureLayer)
        segmentedControl.isEnabled = true
        segmentedControlValueChanged(segmentedControl)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["CustomDictionaryStyleViewController"]
        
        featureLayer.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.setupUI()
            }
        }
    }
}
