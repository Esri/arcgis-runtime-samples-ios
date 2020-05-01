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
            mapView.map = AGSMap(basemap: .topographicVector())
            let initialViewpoint = AGSViewpoint(latitude: -9812698.37297436, longitude: 5131928.33743317, scale: 73.4352610787649)
            mapView.map?.initialViewpoint = initialViewpoint
            mapView.graphicsOverlays.add(associationsOverlay)
        }
    }
    
    private let utilityNetwork = AGSUtilityNetwork(url: URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!)
    private let maxScale = 2000.0
    private var associationsOverlay = AGSGraphicsOverlay()
    private let attachmentSymbol = AGSSimpleLineSymbol(style: .dot, color: .green, width: 5)
    private let connectivitySymbol = AGSSimpleLineSymbol(style: .dot, color: .red, width: 5)
    let attachmentImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
    let connectivityImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
//    var associations: [AGSUtilityAssociation]?

    func loadUtilityNetwork() {
            utilityNetwork.load { [weak self] error in
                if let error = error {
                    self?.presentAlert(error: error)
                    return
                } else {
                    guard let self = self else { return }
                    // Get all the edges and junctions in the network.
                   let edges = self.utilityNetwork.definition.networkSources.filter { $0.sourceType == .edge }
                   let junctions = self.utilityNetwork.definition.networkSources.filter { $0.sourceType == .junction }
                   
                   // Add all edges that are not subnet lines to the map.
                   edges.filter { $0.sourceUsageType != .subnetLine }.forEach { source in
                       self.mapView.map?.operationalLayers.add(AGSFeatureLayer(featureTable: source.featureTable))
                   }
                   // Add all the junctions to the map.
                   junctions.forEach { source in
                       self.mapView.map?.operationalLayers.add(AGSFeatureLayer(featureTable: source.featureTable))
                   }
           //                let attachmentType = AGSUtilityAssociationType.attachment
           //                let connectivityType = AGSUtilityAssociationType.connectivity
                   let attachmentValue = AGSUniqueValue(description: "Attachment", label: "", symbol: self.attachmentSymbol, values: [AGSUtilityAssociationType.attachment])
                   let connectivityValue = AGSUniqueValue(description: "Connectivity", label: "", symbol: self.connectivitySymbol, values: [AGSUtilityAssociationType.connectivity])
               
                   self.associationsOverlay.renderer = AGSUniqueValueRenderer(fieldNames: ["AssociationType"], uniqueValues: [attachmentValue, connectivityValue], defaultLabel: "", defaultSymbol: nil)
                   // Populate the legened.
                   self.attachmentSymbol.createSwatch(withBackgroundColor: nil, screen: .main) { [weak self] (image, error) in
                       if let image = image {
                           self?.attachmentImage.image = image
                       } else if let error = error {
                           print("Error creating swatch: \(error)")
                       }
                   }
                   self.connectivitySymbol.createSwatch(withBackgroundColor: nil, screen: .main) { [weak self] (image, error) in
                       if let image = image {
                           self?.connectivityImage.image = image
                       } else if let error = error {
                           print("Error creating swatch: \(error)")
                       }
                   }
//                    self.mapViewDidChange()
                }
            }
    }
    
    func addAssociationGraphics() {
//        let associationsGroup = DispatchGroup()
//        if utilityNetwork.loadStatus == .notLoaded {
//            loadUtilityNetwork()
//        }
        
//        associationsGroup.enter()
        // Check if the current viewpoint is outside of the max scale.
        if let targetScale = mapView.currentViewpoint(with: .centerAndScale)?.targetScale {
            if targetScale >= maxScale {
                print("inside targetScale")
                return
            }
        }
        
        // Check if the current viewpoint has an extent.
        if let extent = mapView.currentViewpoint(with: .boundingGeometry)?.targetGeometry.extent {
            print("inside extent")
            //Get all of the associations in extent of the viewpoint.
            utilityNetwork.associations(withExtent: extent) { [weak self] (associations, error) in
                if let error = error {
                    print("Error loading associations: \(error)")
                } else {
                    guard let self = self else { return }
                    associations?.forEach { association in
                        // Check if the graphics overlay already contains the association.
                        let graphics = self.associationsOverlay.graphics as! [AGSGraphic]
                        let associationGID = association.globalID
                        let existingAssociations = graphics.filter { $0.attributes["GlobalId"] as! UUID == associationGID }
                        if existingAssociations.isEmpty {
                            let graphic = AGSGraphic(geometry: association.geometry, symbol: .none, attributes: ["GlobalId": associationGID, "AssociationType": association.associationType])
                            self.associationsOverlay.graphics.add(graphic)
                        }
                    }
                }
            }
        }
    }
    
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
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DisplayUtilityAssociationVC"]
    }
}
