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

class DisplayContentUtilityNetworkContainerViewController: UIViewController, AGSGeoViewTouchDelegate {
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
        }
    }
    @IBOutlet var containerView: UIView!
    @IBOutlet var exitBarButtonItem: UIBarButtonItem!
    
    let featureServiceURL = URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer")!
    var utilityNetwork: AGSUtilityNetwork?
    var containerFeature: AGSArcGISFeature?
    var previousViewpoint: AGSViewpoint?
    
    let boundingBoxSymbol = AGSSimpleLineSymbol(style: .dash, color: .yellow, width: 3)
    let attachmentSymbol = AGSSimpleLineSymbol(style: .dot, color: .blue, width: 3)
    let connectivitySymbol = AGSSimpleLineSymbol(style: .dot, color: .red, width: 3)
    var map = AGSMap()
    
    func makeMap() -> AGSMap {
        let webMapURL = URL(string: "https://ss7portal.arcgisonline.com/arcgis/home/item.html?id=5b64cf7a89ca4f98b5ed3da545d334ef")!
        let map = AGSMap(url: webMapURL)!
        return map
    }
    
    @IBAction func exitContainerView() {
        containerView.isHidden = true
        containerFeature = nil
        exitBarButtonItem.isEnabled = false
        (mapView.graphicsOverlays[0] as? AGSGraphicsOverlay)?.graphics.removeAllObjects()
        (mapView.map?.operationalLayers as? [AGSLayer])?.forEach { layer in
            layer.isVisible = true
            if let previousViewpoint = previousViewpoint {
                mapView.setViewpoint(previousViewpoint)
            }
        }
    }
    
    func loadUtilityNetwork() {
        utilityNetwork = AGSUtilityNetwork(url: featureServiceURL, map: mapView.map!)
        utilityNetwork?.load { [weak self] error in
            guard let self = self else { return }
            // Add self as the touch delegate for the map view.
            self.mapView.touchDelegate = self
            if let error = error {
                self.presentAlert(error: error)
            }
        }
    }
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadUtilityNetwork()
        mapView.graphicsOverlays.add(AGSGraphicsOverlay())
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["DisplayContentUtilityNetworkContainer"]
    }
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if !containerView.isHidden {
            return
        }
        mapView.identifyLayers(atScreenPoint: screenPoint, tolerance: 5, returnPopupsOnly: false) { [weak self] (layerResults, error) in
            guard let self = self else { return }
            // A map containing SubtypeFeatureLayer is expected to have features as part of its sublayer's result.
            layerResults?.forEach { layerResult in
                if self.containerFeature == nil, layerResult.layerContent is AGSSubtypeFeatureLayer {
                    layerResult.sublayerResults.forEach { sublayerResult in
                        sublayerResult.geoElements.forEach { geoElement in
                            if self.containerFeature == nil, let feature = geoElement as? AGSArcGISFeature {
                                self.containerFeature = feature
                            }
                        }
                    }
                }
            }
            guard let containerFeature = self.containerFeature, let containerElement = self.utilityNetwork?.createElement(with: containerFeature) else { return }
            // Get the containment associations from this element to display its content.
            self.utilityNetwork?.associations(with: containerElement, type: .containment) {containmentAssociations, error in
                var contentElements = [AGSUtilityElement]()
                containmentAssociations?.forEach { association in
                    var otherElement: AGSUtilityElement
                    if association.fromElement.objectID == containerElement.objectID {
                        otherElement = association.toElement
                    } else {
                        otherElement = association.fromElement
                    }
                    contentElements.append(otherElement)
                    if !contentElements.isEmpty {
                        self.previousViewpoint = self.mapView.currentViewpoint(with: .boundingGeometry)
                        (self.mapView.map?.operationalLayers as? [AGSLayer])?.forEach { layer in
                            layer.isVisible = false
                        }
                        // Set container view visibility to visible.
                        self.containerView.isHidden = false
                        let overlay = self.mapView.graphicsOverlays.firstObject as? AGSGraphicsOverlay
                        self.utilityNetwork?.features(for: contentElements) { (contentFeatures, error) in
                            contentFeatures?.forEach { content in
                                let symbol = (content.featureTable as? AGSArcGISFeatureTable)?.layerInfo?.drawingInfo?.renderer?.symbol(for: content)
                                overlay?.graphics.add(AGSGraphic(geometry: content.geometry, symbol: symbol))
                            }
                            var boundingBox: AGSGeometry?
                            if overlay?.graphics.count == 1, (overlay?.graphics[0] as? AGSGraphic)?.geometry == mapPoint {
                                self.mapView.setViewpointCenter(mapPoint, scale: containerElement.assetType.containerViewScale)
                                boundingBox = self.mapView.currentViewpoint(with: .boundingGeometry)?.targetGeometry
                            } else {
                                boundingBox = AGSGeometryEngine.bufferGeometry(overlay!.extent, byDistance: 0.05)
                            }
                            overlay?.graphics.add(AGSGraphic(geometry: boundingBox, symbol: self.boundingBoxSymbol))
                            self.mapView.setViewpointGeometry(AGSGeometryEngine.bufferGeometry(overlay!.extent, byDistance: 0.05)!)
                            
                            // Get the associations for this extent to display how content features are attached or connected.
                            self.utilityNetwork?.associations(withExtent: overlay!.extent) { (containmentAssociations, error) in
                                containmentAssociations?.forEach { association in
                                    var symbol = AGSSymbol()
                                    if association.associationType == .attachment {
                                        symbol = self.attachmentSymbol
                                    } else {
                                        symbol = self.connectivitySymbol
                                    }
                                    overlay?.graphics.add(AGSGraphic(geometry: association.geometry, symbol: symbol))
                                }
                                self.exitBarButtonItem.isEnabled = true
                            }
                        }
                    }
                }
            }
        }
    }
}
