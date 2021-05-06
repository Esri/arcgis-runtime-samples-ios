// Copyright 2020 Esri.
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

class DisplaySubtypeFeatureLayerViewController: UIViewController {
    // The map view managed by the view controller.
    @IBOutlet private weak var mapView: AGSMapView! {
        didSet {
            AGSAuthenticationManager.shared().delegate = self
            mapView.map = makeMap()
            mapView.setViewpoint(AGSViewpoint(targetExtent: AGSEnvelope(xMin: -9812691.11079696, yMin: 5128687.20710657, xMax: -9812377.9447607, yMax: 5128865.36767282, spatialReference: .webMercator())))
        }
    }
    
    @IBOutlet var settingsButton: UIBarButtonItem!
    @IBOutlet var currentScaleLabel: UILabel!
    var subtypeSublayer: AGSSubtypeSublayer!
    var originalRenderer: AGSRenderer!
    // The observation of the map view's map scale.
    private var mapScaleObservation: NSKeyValueObservation?
    
    var subtypeFeatureLayer: AGSSubtypeFeatureLayer? {
        didSet {
            subtypeFeatureLayer?.load { [weak self] (error) in
                guard let self = self else { return }
                if let error = error {
                    self.presentAlert(error: error)
                } else if let layer = self.subtypeFeatureLayer {
                    self.subtypeSublayer = layer.sublayer(withName: "Street Light")
                    self.originalRenderer = self.subtypeSublayer?.renderer
                    self.subtypeSublayer?.labelsEnabled = true
                    self.settingsButton.isEnabled = true
                    // Make and add the labels.
                    let label = self.makeLabelDefinition()
                    self.subtypeSublayer?.labelDefinitions.append(label)
                }
            }
        }
    }
    
    func makeMap() -> AGSMap {
        let map = AGSMap(basemapStyle: .arcGISStreetsNight)
        // Create a subtype feature layer from a service feature table.
        let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer/0")
        let featureTable = AGSServiceFeatureTable(url: featureServiceURL!)
        subtypeFeatureLayer = AGSSubtypeFeatureLayer(featureTable: featureTable)
        subtypeFeatureLayer?.scaleSymbols = false
        map.operationalLayers.add(subtypeFeatureLayer!)
        return map
    }
    
    private func makeLabelDefinition() -> AGSLabelDefinition {
        // Make and stylize the text symbol.
        let textSymbol = AGSTextSymbol()
        textSymbol.backgroundColor = .clear
        textSymbol.outlineColor = .white
        textSymbol.color = .blue
        textSymbol.haloColor = .white
        textSymbol.haloWidth = 2
        textSymbol.size = 10.5
        // Make a label definition and adjust its properties.
        let labelDefinition = AGSLabelDefinition()
        labelDefinition.expression = AGSArcadeLabelExpression(arcadeString: "$feature.nominalvoltage")
        labelDefinition.placement = .pointAboveRight
        labelDefinition.useCodedValues = true
        labelDefinition.textSymbol = textSymbol
        return  labelDefinition
    }
    
    // The formatter used to generate strings from scale values.
    private let scaleFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()
    
    // Called in response to the map view's map scale changing.
    func mapScaleDidChange() {
        // Update the text of the Current Map Scale label.
        let mapScale = mapView.mapScale
        let updatedText = String(format: "1:%@", scaleFormatter.string(from: mapScale as NSNumber)!)
        currentScaleLabel.text = "Current scale: " + updatedText
    }
    
     override func viewDidLoad() {
        super.viewDidLoad()
        
        mapScaleObservation = mapView.observe(\.mapScale, options: .initial) { [weak self] (_, _) in
            DispatchQueue.main.async { self?.mapScaleDidChange() }
        }
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DisplaySubtypeFeatureLayerViewController", "DisplaySubtypeSettingsViewController"]
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.topViewController as? DisplaySubtypeSettingsViewController {
            controller.map = mapView?.map
            controller.mapScale = mapView.mapScale
            controller.minScale = subtypeSublayer.minScale
            controller.subtypeSublayer = subtypeSublayer
            controller.originalRenderer = self.originalRenderer
            navController.presentationController?.delegate = self
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension DisplaySubtypeFeatureLayerViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // Ensure that the settings show in a popover even on small displays.
        return .none
    }
}

extension DisplaySubtypeFeatureLayerViewController: AGSAuthenticationManagerDelegate {
    func authenticationManager(_ authenticationManager: AGSAuthenticationManager, didReceive challenge: AGSAuthenticationChallenge) {
        // NOTE: Never hardcode login information in a production application. This is done solely for the sake of the sample.
        let credentials = AGSCredential(user: "viewer01", password: "I68VGU^nMurF")
        challenge.continue(with: credentials)
    }
}
