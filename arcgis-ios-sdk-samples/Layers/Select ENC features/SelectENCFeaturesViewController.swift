// Copyright 2021 Esri
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

class SelectENCFeaturesViewController: UIViewController {
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISOceans)
            mapView.touchDelegate = self
            mapView.callout.isAccessoryButtonHidden = true
        }
    }
    
    /// The ENC layer that contains the current selected feature.
    var currentENCLayer: AGSENCLayer?
    /// A reference to the cancelable identify layer operation.
    var identifyOperation: AGSCancelable?
    
    /// A URL to the temporary SENC data directory.
    let temporaryURL: URL = {
        let directoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(ProcessInfo().globallyUniqueString)
        // Create and return the full, unique URL to the temporary folder.
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }()
    
    /// Load the ENC dataset and add it to the map view.
    /// - Parameter mapView: The map view managed by the view controller.
    func addENCExchangeSet(mapView: AGSMapView) {
        let map = mapView.map!
        // Load catalog file in ENC exchange set from bundle.
        let catalogURL = Bundle.main.url(
            forResource: "CATALOG",
            withExtension: "031",
            subdirectory: "ExchangeSetWithoutUpdates/ENC_ROOT"
        )!
        let encExchangeSet = AGSENCExchangeSet(fileURLs: [catalogURL])
        
        // URL to the "hydrography" data folder that contains the "S57DataDictionary.xml" file.
        let hydrographyDirectory = Bundle.main.url(
            forResource: "S57DataDictionary",
            withExtension: "xml",
            subdirectory: "hydrography"
        )!
        .deletingLastPathComponent()
        // Set environment settings for loading the dataset.
        let environmentSettings = AGSENCEnvironmentSettings.shared()
        environmentSettings.resourceDirectory = hydrographyDirectory
        // The SENC data directory is for temporarily storing generated files.
        environmentSettings.sencDataDirectory = temporaryURL
        // Update the display settings to make the chart less cluttered.
        updateDisplaySettings(displaySettings: environmentSettings.displaySettings)
        
        encExchangeSet.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Create a list of ENC layers from datasets.
                let encLayers = encExchangeSet.datasets.map { AGSENCLayer(cell: AGSENCCell(dataset: $0)) }
                // Add layers to the map.
                map.operationalLayers.addObjects(from: encLayers)
                mapView.setViewpoint(AGSViewpoint(latitude: -32.5, longitude: 60.95, scale: 1e5))
            }
        }
    }
    
    /// Update the display settings to make the chart less cluttered.
    func updateDisplaySettings(displaySettings: AGSENCDisplaySettings) {
        displaySettings.textGroupVisibilitySettings.geographicNames = false
        displaySettings.textGroupVisibilitySettings.natureOfSeabed = false
        displaySettings.viewingGroupSettings.buoysBeaconsAidsToNavigation = false
        displaySettings.viewingGroupSettings.depthContours = false
        displaySettings.viewingGroupSettings.spotSoundings = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["SelectENCFeaturesViewController"]
        addENCExchangeSet(mapView: mapView)
    }
    
    deinit {
        // Recursively remove all files in the sample-specific
        // temporary folder and the folder itself.
        try? FileManager.default.removeItem(at: temporaryURL)
        // Reset ENC environment display settings.
        let displaySettings = AGSENCEnvironmentSettings.shared().displaySettings
        displaySettings.textGroupVisibilitySettings.resetToDefaults()
        displaySettings.viewingGroupSettings.resetToDefaults()
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension SelectENCFeaturesViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Dismiss any presenting callout.
        mapView.callout.dismiss()
        // Clear selection before identifying layers.
        currentENCLayer?.clearSelection()
        // Clear in-progress identify operation.
        identifyOperation?.cancel()
        
        // Identify the tapped feature.
        identifyOperation = mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 10, returnPopupsOnly: false) { [weak self] identifyResults, _ in
            guard let self = self else { return }
            self.identifyOperation = nil
            guard let results = identifyResults,
                  !results.isEmpty,
                  let firstResult = results.first(where: { $0.layerContent is AGSENCLayer }),
                  let containingLayer = firstResult.layerContent as? AGSENCLayer,
                  let firstFeature = firstResult.geoElements.first as? AGSENCFeature else {
                      return
                  }
            self.currentENCLayer = containingLayer
            containingLayer.select(firstFeature)
            self.mapView.callout.title = firstFeature.acronym
            self.mapView.callout.detail = firstFeature.featureDescription
            self.mapView.callout.show(at: mapPoint, screenOffset: .zero, rotateOffsetWithMap: false, animated: true)
        }
    }
}
