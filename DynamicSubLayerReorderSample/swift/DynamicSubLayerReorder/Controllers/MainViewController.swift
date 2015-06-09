/*
Copyright 2015 Esri

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

import UIKit
import ArcGIS

let BASEMAP_URL = "http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer"
let DYNAMIC_LAYER_URL = "http://sampleserver6.arcgisonline.com/arcgis/rest/services/USA/MapServer"

class MainViewController: UIViewController, AGSLayerDelegate, LayersListDelegate {

    @IBOutlet weak var mapView:AGSMapView!
    @IBOutlet weak var listContainerView:UIView!
    
    var dynamicMapServiceLayer:AGSDynamicMapServiceLayer!
    var layersListViewController:LayersListViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the basemap layer
        let tiledLayerURL = NSURL(string: BASEMAP_URL)
        let tiledLayer = AGSTiledMapServiceLayer(URL: tiledLayerURL)
        self.mapView.addMapLayer(tiledLayer)
        
        //add the dynamic layer
        let dynamicLayerURL = NSURL(string: DYNAMIC_LAYER_URL)
        self.dynamicMapServiceLayer = AGSDynamicMapServiceLayer(URL: dynamicLayerURL)
        self.dynamicMapServiceLayer.delegate = self
        self.mapView.addMapLayer(self.dynamicMapServiceLayer)
        
        //zoom into the California
        let envelope = AGSEnvelope(xmin: -14029650.509177, ymin: 3560436.632155, xmax: -12627306.217347, ymax: 5430229.021262, spatialReference:AGSSpatialReference.webMercatorSpatialReference())
        self.mapView.zoomToEnvelope(envelope, animated:false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - AGSLayerDelegate
    
    func layer(layer: AGSLayer!, didFailToLoadWithError error: NSError!) {
        //notify the user of the error using the alert view
        UIAlertView(title: "Error", message: error.localizedDescription, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    func layerDidLoad(layer: AGSLayer!) {
        if layer == self.dynamicMapServiceLayer {
            //un hide the container view
            self.listContainerView.hidden = false
            //pass the dynamicLayerInfos array to the list view
            self.layersListViewController.layerInfos = self.dynamicMapServiceLayer.mapServiceInfo.layerInfos as! [AGSLayerInfo]
        }
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        //save the reference to the LayersListViewController
        //when its embeded in the container view
        //and assign self as the delegate
        if segue.identifier == "ListEmbedSegue" {
            self.layersListViewController = segue.destinationViewController as! LayersListViewController
            self.layersListViewController.delegate = self
        }
    }
    
    //MARK: - LayersListDelegate
    
    func layersListViewController(layersListViewController: LayersListViewController, didUpdateLayerInfos dynamicLayerInfos: [AGSDynamicLayerInfo]) {
        //assign the new array of AGSDynamicLayerInfo on the dynamicMapServiceLayer
        //and refresh to update the changes
        self.dynamicMapServiceLayer.dynamicLayerInfos = dynamicLayerInfos
        self.dynamicMapServiceLayer.refresh()
    }
}
