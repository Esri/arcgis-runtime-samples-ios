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

class FindAddressViewController: UIViewController, AGSGeoViewTouchDelegate, UISearchBarDelegate, UIAdaptivePresentationControllerDelegate, WorldAddressesVCDelegate {
    
    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var button:UIButton!
    @IBOutlet private var searchBar:UISearchBar!
    
    private var locatorTask:AGSLocatorTask!
    private var geocodeParameters:AGSGeocodeParameters!
    private var graphicsOverlay:AGSGraphicsOverlay!
    
    private let locatorURL = "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FindAddressViewController", "WorldAddressesViewController"]
        
        //instantiate a map with an imagery with labels basemap
        let map = AGSMap(basemap: .imageryWithLabels())
        self.mapView.map = map
        self.mapView.touchDelegate = self
        
        //initialize the graphics overlay and add to the map view
        self.graphicsOverlay = AGSGraphicsOverlay()
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        //initialize locator task
        self.locatorTask = AGSLocatorTask(url: URL(string: self.locatorURL)!)
        
        //initialize geocode parameters
        self.geocodeParameters = AGSGeocodeParameters()
        self.geocodeParameters.resultAttributeNames.append(contentsOf: ["*"])
        self.geocodeParameters.minScore = 75
        
        //register self for the keyboard show notification
        //in order to un hide the cancel button for search
        NotificationCenter.default.addObserver(self, selector: #selector(FindAddressViewController.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    //method that returns a graphic object for the specified point and attributes
    //also sets the leader offset and offset
    private func graphicForPoint(_ point: AGSPoint, attributes: [String: AnyObject]?) -> AGSGraphic {
        let markerImage = UIImage(named: "RedMarker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height/2
        symbol.offsetY = markerImage.size.height/2
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: attributes)
        return graphic
    }
    
    private func geocodeSearchText(_ text:String) {
        //clear already existing graphics
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //dismiss the callout if already visible
        self.mapView.callout.dismiss()
        
        //perform geocode with input text
        self.locatorTask.geocode(withSearchText: text, parameters: self.geocodeParameters, completion: { [weak self] (results:[AGSGeocodeResult]?, error:Error?) -> Void in
            if let error = error {
                self?.presentAlert(error: error)
            }
            else {
                if let results = results , results.count > 0 {
                    //create a graphic for the first result and add to the graphics overlay
                    let graphic = self?.graphicForPoint(results[0].displayLocation!, attributes: results[0].attributes as [String : AnyObject]?)
                    self?.graphicsOverlay.graphics.add(graphic!)
                    //zoom to the extent of the result
                    if let extent = results[0].extent {
                        self?.mapView.setViewpointGeometry(extent, completion: nil)
                    }
                }
                else {
                    //provide feedback in case of failure
                    self?.presentAlert(message: "No results found")
                }
            }
        })
    }
    
    //MARK: - Callout
    
    //method shows the callout for the specified graphic,
    //populates the title and detail of the callout with specific attributes
    //hides the accessory button
    private func showCalloutForGraphic(_ graphic:AGSGraphic, tapLocation:AGSPoint) {
        let addressType = graphic.attributes["Addr_type"] as! String
        self.mapView.callout.title = graphic.attributes["Match_addr"] as? String ?? ""
        
        if addressType == "POI" {
            self.mapView.callout.detail = graphic.attributes["Place_addr"] as? String ?? ""
        }
        else {
            self.mapView.callout.detail = nil
        }
        
        self.mapView.callout.isAccessoryButtonHidden = true
        self.mapView.callout.show(for: graphic, tapLocation: tapLocation, animated: true)
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //dismiss the callout
        self.mapView.callout.dismiss()
        
        //identify graphics at the tapped location
        self.mapView.identify(self.graphicsOverlay, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 1) { (result: AGSIdentifyGraphicsOverlayResult) -> Void in
            if let error = result.error {
                self.presentAlert(error: error)
            }
            else if result.graphics.count > 0 {
                //show callout for the graphic
                self.showCalloutForGraphic(result.graphics[0], tapLocation: mapPoint)
            }
        }
    }
    
    //MARK: - UISearchBar delegates
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.geocodeSearchText(searchBar.text!)
        self.hideKeyboard()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.graphicsOverlay.graphics.removeAllObjects()
            self.mapView.callout.dismiss()
        }
    }
    
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        self.performSegue(withIdentifier: "AddressesListSegue", sender: self)
    }
    
    //MARK: - Actions
    @objc func keyboardWillShow(_ sender:AnyObject) {
        self.button.isHidden = false
    }
    
    @IBAction func hideKeyboard() {
        self.searchBar.resignFirstResponder()
        self.button.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddressesListSegue" {
            let controller = segue.destination as! WorldAddressesViewController
            controller.presentationController?.delegate = self
            controller.popoverPresentationController?.sourceView = self.view
            controller.popoverPresentationController?.sourceRect = self.searchBar.frame
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            controller.delegate = self
        }
    }
    
    //MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
    
        return UIModalPresentationStyle.none
    }
    
    //MARK: - AddressesListVCDelegate
    
    func worldAddressesViewController(_ worldAddressesViewController: WorldAddressesViewController, didSelectAddress address: String) {
        self.searchBar.text = address
        self.geocodeSearchText(address)
        self.dismiss(animated: true, completion: nil)
        self.hideKeyboard()
    }
}
