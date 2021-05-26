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

class FindAddressViewController: UIViewController, AGSGeoViewTouchDelegate, UISearchBarDelegate, UIAdaptivePresentationControllerDelegate, WorldAddressesViewControllerDelegate {
    @IBOutlet private var mapView: AGSMapView! {
        didSet {
            // Instantiate a map with an imagery with labels basemap.
            mapView.map = AGSMap(basemapStyle: .arcGISImagery)
            mapView.touchDelegate = self
            
            // Add the graphics overlay to the map view.
            mapView.graphicsOverlays.add(self.graphicsOverlay)
        }
    }
    @IBOutlet private var button: UIButton!
    @IBOutlet private var searchBar: UISearchBar!
    
    private var locatorTask = AGSLocatorTask(url: URL(string: "https://geocode-api.arcgis.com/arcgis/rest/services/World/GeocodeServer")!)
    private let graphicsOverlay = AGSGraphicsOverlay()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FindAddressViewController", "WorldAddressesViewController"]
        
        // Register self for the show keyboard notification
        // in order to display the cancel button for search.
        NotificationCenter.default.addObserver(self, selector: #selector(FindAddressViewController.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    /// Returns a graphic object for the specified point and attributes and set the leader offset and offset.
    private func graphicForPoint(_ point: AGSPoint, attributes: [String: AnyObject]?) -> AGSGraphic {
        let markerImage = UIImage(named: "RedMarker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height / 2
        symbol.offsetY = markerImage.size.height / 2
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: attributes)
        return graphic
    }
    
    private func geocodeSearchText(_ text: String) {
        // Clear already existing graphics.
        self.graphicsOverlay.graphics.removeAllObjects()
        
        // Dismiss the callout if already visible.
        self.mapView.callout.dismiss()
        
        // Initialize geocode parameters.
        let geocodeParameters = AGSGeocodeParameters()
        geocodeParameters.resultAttributeNames.append(contentsOf: ["*"])
        geocodeParameters.minScore = 75
        // Perform geocode with input text.
        self.locatorTask.geocode(withSearchText: text, parameters: geocodeParameters) { [weak self] (results: [AGSGeocodeResult]?, error: Error?) in
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
            } else if let result = results?.first {
                // Create a graphic for the first result and add to the graphics overlay.
                let graphic = self.graphicForPoint(result.displayLocation!, attributes: result.attributes as [String: AnyObject]?)
                self.graphicsOverlay.graphics.add(graphic)
                // Zoom to the extent of the result.
                if let extent = result.extent {
                    self.mapView.setViewpointGeometry(extent, completion: nil)
                }
            } else {
                // Provide feedback in case of failure.
                self.presentAlert(message: "No results found")
            }
        }
    }
    
    // MARK: - Callout
    
    /// Show the callout for the specified graphic by populating the title and detail of the callout with specific attributes.
    private func showCalloutForGraphic(_ graphic: AGSGraphic, tapLocation: AGSPoint) {
        let addressType = graphic.attributes["Addr_type"] as! String
        self.mapView.callout.title = graphic.attributes["Match_addr"] as? String ?? ""
        
        if addressType == "POI" {
            self.mapView.callout.detail = graphic.attributes["Place_addr"] as? String ?? ""
        } else {
            self.mapView.callout.detail = nil
        }
        
        self.mapView.callout.isAccessoryButtonHidden = true
        self.mapView.callout.show(for: graphic, tapLocation: tapLocation, animated: true)
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Dismiss the callout.
        self.mapView.callout.dismiss()
        
        // Identify graphics at the tapped location.
        self.mapView.identify(self.graphicsOverlay, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 1) { (result: AGSIdentifyGraphicsOverlayResult) in
            if let error = result.error {
                self.presentAlert(error: error)
            } else if let graphic = result.graphics.first {
                // Show callout for the graphic.
                self.showCalloutForGraphic(graphic, tapLocation: mapPoint)
            }
        }
    }
    
    // MARK: - UISearchBar delegates
    
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
    
    // MARK: - Actions
    @objc
    func keyboardWillShow(_ sender: AnyObject) {
        self.button.isHidden = false
    }
    
    @IBAction func hideKeyboard() {
        self.searchBar.resignFirstResponder()
        self.button.isHidden = true
    }
    
    // MARK: - Navigation
    
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
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    // MARK: - WorldAddressesViewControllerDelegate
    
    func worldAddressesViewController(_ worldAddressesViewController: WorldAddressesViewController, didSelectAddress address: String) {
        self.searchBar.text = address
        self.geocodeSearchText(address)
        self.dismiss(animated: true)
        self.hideKeyboard()
    }
}
