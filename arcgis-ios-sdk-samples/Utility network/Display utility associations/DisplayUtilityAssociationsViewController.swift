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

class DisplayUtilityAssociationsViewController: UIViewController {
    // Set the map.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            let map = AGSMap(basemapStyle: .arcGISTopographic)
            // Add the utility network to the map.
            map.utilityNetworks.add(utilityNetwork)
            mapView.map = map
            mapView.setViewpoint(AGSViewpoint(latitude: 41.8057655, longitude: -88.1489692, scale: 70.5310735))
            mapView.graphicsOverlays.add(associationsOverlay)
        }
    }
    
    @IBOutlet var toolbar: UIToolbar!
    
    private let utilityNetwork = AGSUtilityNetwork(url: URL(string: "https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!)
    private let maxScale = 2000.0
    private let associationsOverlay = AGSGraphicsOverlay()
    private let attachmentSymbol = AGSSimpleLineSymbol(style: .dot, color: .green, width: 5)
    private let connectivitySymbol = AGSSimpleLineSymbol(style: .dot, color: .red, width: 5)
    
    func loadUtilityNetwork() {
        // WARNING: Never hardcode login information in a production application. This is done solely for the sake of the sample.
        utilityNetwork.credential = AGSCredential(user: "viewer01", password: "I68VGU^nMurF")
        utilityNetwork.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // Get all the edges and junctions in the network.
                let sourcesByType = Dictionary(grouping: self.utilityNetwork.definition.networkSources) { $0.sourceType }
                let operationalLayers = self.mapView.map?.operationalLayers
                // Add all edges that are not subnet lines to the map.
                let edgeLayers = sourcesByType[.edge]!
                    .filter { $0.sourceUsageType != .subnetLine }
                    .map { AGSFeatureLayer(featureTable: $0.featureTable) }
                operationalLayers?.addObjects(from: edgeLayers)
                // Add all the junctions to the map.
                let junctionLayers = sourcesByType[.junction]!.map { AGSFeatureLayer(featureTable: $0.featureTable) }
                operationalLayers?.addObjects(from: junctionLayers)
                
                // Create a renderer for the associations.
                let attachmentValue = AGSUniqueValue(description: "Attachment", label: "", symbol: self.attachmentSymbol, values: [AGSUtilityAssociationType.attachment])
                let connectivityValue = AGSUniqueValue(description: "Connectivity", label: "", symbol: self.connectivitySymbol, values: [AGSUtilityAssociationType.connectivity])
                self.associationsOverlay.renderer = AGSUniqueValueRenderer(fieldNames: ["AssociationType"], uniqueValues: [attachmentValue, connectivityValue], defaultLabel: "", defaultSymbol: nil)
                
                self.createSwatches()
                self.addAssociationGraphics()
                self.mapViewDidChange()
            }
        }
    }
    
    func addAssociationGraphics() {
        // Check if the current viewpoint is outside of the max scale.
        if let viewpoint = mapView.currentViewpoint(with: .centerAndScale),
            viewpoint.targetScale >= maxScale {
            return
        }
        
        // Check if the current viewpoint has an extent.
        if let viewpoint = mapView.currentViewpoint(with: .boundingGeometry) {
            // Get all of the associations in extent of the viewpoint.
            utilityNetwork.associations(withExtent: viewpoint.targetGeometry.extent) { [weak self] (associations, error) in
                guard let self = self else { return }
                if let error = error {
                    self.presentAlert(error: error)
                } else if let associations = associations {
                    let graphics: [AGSGraphic] = associations.compactMap { association in
                        // If it the current association does not exist, add it to the graphics overlay.
                        let associationGID = association.globalID
                        guard !self.associationsOverlay.graphics.contains(where: {
                            ($0 as! AGSGraphic).attributes["GlobalId"] as? UUID == associationGID
                        }) else {
                            return nil
                        }
                        let symbol: AGSSymbol
                        switch association.associationType {
                        case .attachment:
                            symbol = self.attachmentSymbol
                        case .connectivity:
                            symbol = self.connectivitySymbol
                        default:
                            return nil
                        }
                        return AGSGraphic(
                            geometry: association.geometry,
                            symbol: symbol,
                            attributes: [
                                "GlobalId": associationGID,
                                "AssociationType": association.associationType
                            ]
                        )
                    }
                    self.associationsOverlay.graphics.addObjects(from: graphics)
                }
            }
        }
    }
    
    // Populate the legend.
    func createSwatches() {
        let swatchGroup = DispatchGroup()
        var attachmentImage: UIImage?
        var connectivityImage: UIImage?
        swatchGroup.enter()
        attachmentSymbol.createSwatch(withBackgroundColor: nil, screen: .main) { (image, error) in
            defer { swatchGroup.leave() }
            if let error = error {
                self.presentAlert(error: error)
            } else if let image = image {
                attachmentImage = image.withRenderingMode(.alwaysOriginal)
            }
        }
        swatchGroup.enter()
        connectivitySymbol.createSwatch(withBackgroundColor: nil, screen: .main) { (image, error) in
            defer { swatchGroup.leave() }
            if let error = error {
                self.presentAlert(error: error)
            } else if let image = image {
                connectivityImage = image.withRenderingMode(.alwaysOriginal)
            }
        }
        swatchGroup.notify(queue: .main) { [weak self] in
            let attachmentBBI = UIBarButtonItem(image: attachmentImage, style: .plain, target: nil, action: nil)
            let connectivityBBI = UIBarButtonItem(image: connectivityImage, style: .plain, target: nil, action: nil)
            let attachmentLabel = UIBarButtonItem(title: "Attachment", style: .plain, target: nil, action: nil)
            let connectivityLabel = UIBarButtonItem(title: "Connectivity", style: .plain, target: nil, action: nil)
            attachmentLabel.tintColor = .label
            connectivityLabel.tintColor = .label
            let fixedSpace1 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            let fixedSpace2 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            let flexibleSpace1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let flexibleSpace2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            self?.toolbar.items = [attachmentBBI, fixedSpace1, attachmentLabel, flexibleSpace1, connectivityBBI, fixedSpace2, connectivityLabel, flexibleSpace2]
        }
    }
    
    // Observe the viewpoint.
    func mapViewDidChange() {
        self.mapView.viewpointChangedHandler = { [weak self] in
            DispatchQueue.main.async {
                self?.addAssociationGraphics()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadUtilityNetwork()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DisplayUtilityAssociationsViewController"]
    }
}
