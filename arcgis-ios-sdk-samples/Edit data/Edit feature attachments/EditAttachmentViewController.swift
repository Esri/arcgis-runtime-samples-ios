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

class EditAttachmentViewController: UIViewController, AGSGeoViewTouchDelegate, AGSCalloutDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var featureTable:AGSServiceFeatureTable!
    private var featureLayer:AGSFeatureLayer!
    private var lastQuery:AGSCancelable!
    
    private var selectedFeature:AGSArcGISFeature!
    private let FEATURE_SERVICE_URL = "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditAttachmentViewController"]
        
        self.map = AGSMap(basemap: .oceans())
        //set initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -471534.03, y: 7297552.03, spatialReference: AGSSpatialReference.webMercator()), scale: 6e6)
        
        self.featureTable = AGSServiceFeatureTable(url: URL(string: FEATURE_SERVICE_URL)!)
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        
        self.map.operationalLayers.add(self.featureLayer)
        
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        if let lastQuery = self.lastQuery{
            lastQuery.cancel()
        }
        
        //hide the callout
        self.mapView.callout.dismiss()
        
        
        self.lastQuery = self.mapView.identifyLayer(self.featureLayer, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 1) { [weak self] (identifyLayerResult: AGSIdentifyLayerResult) -> Void in
            if let error = identifyLayerResult.error {
                print(error)
            }
            else if let features = identifyLayerResult.geoElements as? [AGSArcGISFeature] , features.count > 0 {
                let feature = features[0]
                //show callout for the first feature
                let title = feature.attributes["typdamage"] as! String
                
                //fetch attachment
                feature.fetchAttachments { (attachments:[AGSAttachment]?, error:Error?) -> Void in
                    if let error = error {
                        print(error)
                    }
                    else if let attachments = attachments {
                        let detail = "Number of attachments :: \(attachments.count)"
                        self?.mapView.callout.title = title
                        self?.mapView.callout.detail = detail
                        self?.mapView.callout.delegate = self
                        self?.mapView.callout.show(for: feature, tapLocation: mapPoint, animated: true)
                        //update selected feature
                        self?.selectedFeature = feature
                    }
                }
            }
        }
    }
    
    //MARK: - AGSCalloutDelegate
    
    func didTapAccessoryButton(for callout: AGSCallout) {
        //hide the callout
        self.mapView.callout.dismiss()
        //show the attachments list vc
        self.performSegue(withIdentifier: "AttachmentsSegue", sender: self)
        
    }
    
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AttachmentsSegue" {
            let controller = segue.destination as! AttachmentsListViewController
            controller.feature = self.selectedFeature
        }
    }
}
