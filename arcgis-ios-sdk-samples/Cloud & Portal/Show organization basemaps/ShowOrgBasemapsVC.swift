// Copyright 2017 Esri.
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

class ShowOrgBasemapsVC: UIViewController, BasemapsCollectionVCDelegate, AGSAuthenticationManagerDelegate {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var visualEffectView: UIVisualEffectView!
    @IBOutlet var settingsView: UIView!
    @IBOutlet var portalURLTextField: UITextField!
    @IBOutlet var anonymousSwitch: UISwitch!
    
    private var portal: AGSPortal!
    private var portalURLString = "https://www.arcgis.com"
    private var anonymousUser = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ShowOrgBasemapsVC", "BasemapHelper", "BasemapsCollectionViewController", "BasemapCell"]
        
        //oAuth setup
        let config = AGSOAuthConfiguration(portalURL: URL(string: self.portalURLString), clientID: "xHx4Nj7q1g19Wh6P", redirectURL: "iOSSamples://auth")
        AGSAuthenticationManager.shared().oAuthConfigurations.add(config)
        AGSAuthenticationManager.shared().credentialCache.removeAllCredentials()
        
        //initialize map with basemap
        let map = AGSMap(basemap: AGSBasemap.terrainWithLabels())
        
        //initial viewpoint
        map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -13176752, y: 4090404, spatialReference: AGSSpatialReference.webMercator()), scale: 300000)
        
        //assign map to the map view
        self.mapView.map = map
        
        //initialize service feature table using url
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/Energy/Geology/FeatureServer/9")!)
        
        //create a feature layer
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        //add the feature layer to the operational layers
        map.operationalLayers.add(featureLayer)
        
        //stylize settings view
        self.settingsView.layer.cornerRadius = 10
        
        //add tap gesture recognizer to visual effect view
        //to hide keyboard on tap
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.visualEffectView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "BasemapsCollectionSegue" {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.viewControllers[0] as! BasemapsCollectionViewController
            controller.delegate = self
            controller.portal = portal
        }
    }
    
    //MARK: - BasemapsCollectionVCDelegate
    
    func basemapsCollectionViewController(_ basemapsCollectionViewController: BasemapsCollectionViewController, didSelectBasemap basemap: AGSBasemap) {
        
        self.dismiss(animated: true, completion: nil)
        
        //update basemap on the map
        self.mapView.map?.basemap = basemap
    }
    
    func basemapsCollectionViewControllerDidCancel(_ basemapsCollectionViewController: BasemapsCollectionViewController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Actions
    
    @IBAction func closeAction() {
        if self.portalURLTextField.text!.isEmpty {
            self.portalURLTextField.text = "https://www.arcgis.com"
        }
        
        self.toggleSettingsView(false)
        
        //update values
        self.anonymousUser = self.anonymousSwitch.isOn
        self.portalURLString = self.portalURLTextField.text!
    }
    
    @IBAction func settingsAction() {
        self.toggleSettingsView(true)
    }
    
    @IBAction func changeBasemapAction() {
        
        self.portal = AGSPortal(url: URL(string: self.portalURLString)!, loginRequired: !self.anonymousUser)
        self.portal.load { [weak self] (error: Error?) in
            if let error = error {
                print(error)
            }
            else {
                self?.performSegue(withIdentifier: "BasemapsCollectionSegue", sender: self!)
            }
        }
    }
    
    func tapAction() {
        if self.portalURLTextField.isFirstResponder {
            self.portalURLTextField.resignFirstResponder()
        }
    }
    
    //MARK: Show/Hide settings view
    
    private func toggleSettingsView(_ toggleOn: Bool) {
        self.visualEffectView.isHidden = !toggleOn
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
