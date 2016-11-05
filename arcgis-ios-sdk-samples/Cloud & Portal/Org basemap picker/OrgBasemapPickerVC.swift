//
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

let AGOL_PORTAL_URL_STRING = "https://www.arcgis.com"

class OrgBasemapPickerVC: UIViewController, BasemapsCollectionVCDelegate {
    
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var visualEffectView: UIVisualEffectView!
    @IBOutlet var settingsView: UIView!
    @IBOutlet var portalURLTextField: UITextField!
    @IBOutlet var anonymousSwitch: UISwitch!
    
    private var portalURLString = AGOL_PORTAL_URL_STRING
    private var anonymousUser = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OrgBasemapPickerVC", "BasemapsCollectionViewController", "BasemapCell"]
        
        //initialize map with basemap
        let map = AGSMap(basemap: AGSBasemap.terrainWithLabelsBasemap())
        
        //initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -13176752, y: 4090404, spatialReference: AGSSpatialReference.webMercator()), scale: 300000)
        
        //assign map to the map view
        self.mapView.map = map
        
        //initialize service feature table using url
        let featureTable = AGSServiceFeatureTable(URL: NSURL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/9")!)
        
        //create a feature layer
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        //add the feature layer to the operational layers
        map.operationalLayers.addObject(featureLayer)
        
        //stylize settings view
        self.settingsView.layer.cornerRadius = 10
        
        //add tap gesture recognizer to visual effect view
        //to hide keyboard on tap
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.visualEffectView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "BasemapsCollectionSegue" {
            let controller = segue.destinationViewController as! BasemapsCollectionViewController
            controller.delegate = self
            controller.portalURLString = self.portalURLString
            controller.anonymousUser = self.anonymousUser
        }
    }
    
    //MARK: - BasemapsCollectionVCDelegate
    
    func basemapsCollectionViewController(basemapsCollectionViewController: BasemapsCollectionViewController, didSelectBasemap basemap: AGSBasemap) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
        //update basemap on the map
        self.mapView.map?.basemap = basemap
    }
    
    func basemapsCollectionViewControllerDidCancel(basemapsCollectionViewController: BasemapsCollectionViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: Show/Hide settings view
    
    private func toggleSettingsView(toggleOn: Bool) {
        self.visualEffectView.hidden = !toggleOn
    }
    
    //MARK: - Actions
    
    @IBAction func closeAction() {
        if self.portalURLTextField.text!.isEmpty {
            self.portalURLTextField.text = AGOL_PORTAL_URL_STRING
        }
        
        self.toggleSettingsView(false)
        
        //update values
        self.anonymousUser = self.anonymousSwitch.on
        self.portalURLString = self.portalURLTextField.text!
    }
    
    @IBAction func settingsAction() {
        self.toggleSettingsView(true)
    }
    
    func tapAction() {
        if self.portalURLTextField.isFirstResponder() {
            self.portalURLTextField.resignFirstResponder()
        }
    }
}

