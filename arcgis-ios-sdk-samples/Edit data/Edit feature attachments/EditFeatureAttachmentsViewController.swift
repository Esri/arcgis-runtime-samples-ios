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

class EditFeatureAttachmentsViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView!
    
    private let featureLayer: AGSFeatureLayer
    private var lastQuery: AGSCancelable?
    
    private var selectedFeature: AGSArcGISFeature?
    
    required init?(coder aDecoder: NSCoder) {
        let featureServiceURL = URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0")!
        let featureTable = AGSServiceFeatureTable(url: featureServiceURL)
        self.featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = [
            "EditFeatureAttachmentsViewController",
            "AttachmentsTableViewController"
        ]
        
        let map = AGSMap(basemap: .oceans())
        //set initial viewpoint
        map.initialViewpoint = AGSViewpoint(
            center: AGSPoint(x: 0, y: 0, spatialReference: .webMercator()),
            scale: 100000000
        )
        map.operationalLayers.add(featureLayer)
        
        mapView.map = map
        mapView.touchDelegate = self
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? AttachmentsTableViewController {
            controller.feature = selectedFeature
        }
    }
}

extension EditFeatureAttachmentsViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let lastQuery = lastQuery {
            lastQuery.cancel()
        }
        
        //hide the callout
        mapView.callout.dismiss()
        
        lastQuery = mapView.identifyLayer(featureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 1) { [weak self] (identifyLayerResult: AGSIdentifyLayerResult) in
            guard let self = self else {
                return
            }
            
            if let error = identifyLayerResult.error {
                print(error)
            } else if let features = identifyLayerResult.geoElements as? [AGSArcGISFeature],
                let feature = features.first,
                //show callout for the first feature
                let title = feature.attributes["typdamage"] as? String {
                //fetch attachment
                feature.fetchAttachments { (attachments: [AGSAttachment]?, error: Error?) in
                    if let error = error {
                        print(error)
                    } else if let attachments = attachments {
                        let detail = "Number of attachments: \(attachments.count)"
                        self.mapView.callout.title = title
                        self.mapView.callout.detail = detail
                        self.mapView.callout.delegate = self
                        self.mapView.callout.show(for: feature, tapLocation: mapPoint, animated: true)
                        //update selected feature
                        self.selectedFeature = feature
                    }
                }
            }
        }
    }
}

extension EditFeatureAttachmentsViewController: AGSCalloutDelegate {
    func didTapAccessoryButton(for callout: AGSCallout) {
        //hide the callout
        mapView.callout.dismiss()
        //show the attachments list vc
        performSegue(withIdentifier: "AttachmentsSegue", sender: self)
    }
}
