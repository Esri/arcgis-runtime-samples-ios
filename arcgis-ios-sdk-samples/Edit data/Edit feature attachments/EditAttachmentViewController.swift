// Copyright 2015 Esri.
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

class EditAttachmentViewController: UIViewController, AGSMapViewTouchDelegate, AGSCalloutDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    private var featureTable:AGSServiceFeatureTable!
    private var featureLayer:AGSFeatureLayer!
    private var lastQuery:AGSCancellable!
    
    private var selectedFeature:AGSArcGISFeature!
    private let FEATURE_SERVICE_URL = "http://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["EditAttachmentViewController"]
        
        self.map = AGSMap(basemap: AGSBasemap.oceansBasemap())
        //set initial viewpoint
        self.map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -471534.03, y: 7297552.03, spatialReference: AGSSpatialReference.webMercator()), scale: 6e6)
        
        self.featureTable = AGSServiceFeatureTable(URL: NSURL(string: FEATURE_SERVICE_URL))
        self.featureLayer = AGSFeatureLayer(featureTable: self.featureTable)
        
        self.map.operationalLayers.addObject(self.featureLayer)
        
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView!, didTapAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!) {
        if let lastQuery = self.lastQuery{
            lastQuery.cancel()
        }
        
        //hide the callout
        self.mapView.callout.dismiss()
        
        let tolerance:Double = 22
        let mapTolerance = tolerance * self.mapView.unitsPerPixel
        let envelope = AGSEnvelope(XMin: mappoint.x - mapTolerance,
            yMin: mappoint.y - mapTolerance,
            xMax: mappoint.x + mapTolerance,
            yMax: mappoint.y + mapTolerance,
            spatialReference: self.map.spatialReference)
        
        let queryParams = AGSQueryParameters()
        queryParams.geometry = envelope
        queryParams.outFields = ["*"]
        
        self.lastQuery = self.featureTable.queryFeaturesWithParameters(queryParams, completion: { [weak self] (result:AGSFeatureQueryResult!, error:NSError!) -> Void in
            if let error = error {
                print(error)
            }
            else {
                if let feature = result.enumerator().nextObject() as? AGSArcGISFeature {
                    //show callout for the first feature
                    let title = feature.attributeValueForKey("typdamage") as! String
                    
                    //fetch attachment info
                    feature.fetchAttachmentInfosWithCompletion({ [weak self] (attachmentInfos:[AnyObject]!, error:NSError!) -> Void in
                        if let error = error {
                            print(error)
                        }
                        else {
                            
                            let detail = "Number of attachments :: \(attachmentInfos.count)"
                            self?.mapView.callout.title = title
                            self?.mapView.callout.detail = detail
                            self?.mapView.callout.delegate = self
                            self?.mapView.callout.showCalloutForFeature(feature, layer: self!.featureLayer, tapLocation: mappoint, animated: true)
                            //update selected feature
                            self?.selectedFeature = feature
                        }
                    })
                }
            }
        })
    }
    
    //MARK: - AGSCalloutDelegate
    
    func didTapAccessoryButtonForCallout(callout: AGSCallout) {
        //hide the callout
        self.mapView.callout.dismiss()
        //show the attachments list vc
        self.performSegueWithIdentifier("AttachmentsSegue", sender: self)
        
    }
    
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AttachmentsSegue" {
            let controller = segue.destinationViewController as! AttachmentsListViewController
            controller.feature = self.selectedFeature
        }
    }
}
