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

class DisplayUtilityAssociationVC: UIViewController {
    // Set the map.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapType: .topographicVector, latitude: 41.8057655, longitude: -88.1489692, levelOfDetail: 23)
            mapView.graphicsOverlays.add(associationsOverlay)
        }
    }
    
    @IBOutlet var attachmentBBI: UIBarButtonItem!
    @IBOutlet var connectivityBBI: UIBarButtonItem!
    
    private let utilityNetwork = AGSUtilityNetwork(url: URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!)
    private let maxScale = 2000.0
    private let associationsOverlay = AGSGraphicsOverlay()
    private let attachmentSymbol = AGSSimpleLineSymbol(style: .dot, color: .green, width: 5)
    private let connectivitySymbol = AGSSimpleLineSymbol(style: .dot, color: .red, width: 5)
    
    func loadUtilityNetwork() {
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
                
                // Populate the legened.
                self.attachmentSymbol.createSwatch(withBackgroundColor: nil, screen: .main) { [weak self] (image, error) in
                    if let error = error {
                        print("Error creating swatch: \(error)")
                    } else {
                        self?.attachmentBBI.image = image?.withRenderingMode(.alwaysOriginal)
                    }
                }
                self.connectivitySymbol.createSwatch(withBackgroundColor: nil, screen: .main) { [weak self] (image, error) in
                    if let error = error {
                        print("Error creating swatch: \(error)")
                    } else {
                        self?.connectivityBBI.image = image?.withRenderingMode(.alwaysOriginal)
                    }
                }
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
                    print("Error loading associations: \(error)")
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
                        return AGSGraphic(geometry: association.geometry, symbol: symbol, attributes: ["GlobalId": associationGID, "AssociationType": association.associationType])
                    }
                    self.associationsOverlay.graphics.addObjects(from: graphics)
                }
            }
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
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DisplayUtilityAssociationViewController"]
    }
}
