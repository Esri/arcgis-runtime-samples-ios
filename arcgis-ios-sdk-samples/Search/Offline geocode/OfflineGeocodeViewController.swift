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

class GeocodeOfflineViewController: UIViewController, AGSGeoViewTouchDelegate, UISearchBarDelegate, UIAdaptivePresentationControllerDelegate, SanDiegoAddressesViewControllerDelegate {
    @IBOutlet private var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            // Register self as the touch delegate for the map view.
            mapView.touchDelegate = self
            
            // Add the graphics overlay to the map view.
            mapView.graphicsOverlays.add(self.graphicsOverlay)
            // Zoom to San Diego.
            mapView.setViewpointCenter(AGSPoint(x: -13042254.715252, y: 3857970.236806, spatialReference: .webMercator()), scale: 2e4)
            // Enable magnifier for better experience while using tap and hold to add a location.
            mapView.interactionOptions.isMagnifierEnabled = true
        }
    }
    @IBOutlet private var button: UIButton!
    @IBOutlet private var searchBar: UISearchBar!
    
    private var locatorTask = AGSLocatorTask(name: "SanDiego_StreetAddress")
    private let graphicsOverlay = AGSGraphicsOverlay()
    private var locatorTaskOperation: AGSCancelable!
    private var longPressedAndMoving = false
    
    func makeMap() -> AGSMap {
        // Instantiate map.
        let map = AGSMap()
        // Create a local tiled layer using tile package.
        let path = Bundle.main.path(forResource: "streetmap_SD", ofType: "tpk")!
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(fileURL: URL(fileURLWithPath: path)))
        // Add the local tiled layer.
        map.operationalLayers.add(localTiledLayer)
        return map
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OfflineGeocodeViewController", "SanDiegoAddressesViewController"]
        
        // Add self as the observer for the keyboard show notification.
        // Display a button every time keyboard is displayed so the user
        // can tap and cancel search and hide the keyboard.
        NotificationCenter.default.addObserver(self, selector: #selector(GeocodeOfflineViewController.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    private func geocodeSearchText(_ text: String) {
        // Hide keyboard.
        self.hideKeyboard()
        
        // Dismiss the callout if already visible.
        self.mapView.callout.dismiss()
        
        // Remove all previous graphics.
        self.graphicsOverlay.graphics.removeAllObjects()
        
        // Initialize geocode parameters.
        let geocodeParameters = AGSGeocodeParameters()
        geocodeParameters.resultAttributeNames.append(contentsOf: ["Match_addr"])
        geocodeParameters.minScore = 75
        // Perform geocode with the input.
        self.locatorTask.geocode(withSearchText: text, parameters: geocodeParameters) { [weak self]  (results: [AGSGeocodeResult]?, error: Error?) in
            guard let self = self else {
                return
            }
            
            if let error = error {
                self.presentAlert(error: error)
            } else {
                // If a result was returned display the graphic on the map view
                // using the first result, as it is the more relevant.
                if let result = results?.first {
                    let graphic = self.makeGraphic(point: result.displayLocation!, attributes: result.attributes)
                    self.graphicsOverlay.graphics.add(graphic)
                    
                    // Zoom to the extent of the graphic.
                    self.mapView.setViewpointGeometry(result.displayLocation!.extent, completion: nil)
                } else {
                    // If no result found, inform the user.
                    self.presentAlert(message: "No results found")
                }
            }
        }
    }
    
    private func reverseGeocode(point: AGSPoint) {
        // Clear the search bar text to give feedback that the graphic
        // is based on the tap and not search.
        self.searchBar.text = ""
        
        // Remove all previous graphics.
        self.graphicsOverlay.graphics.removeAllObjects()
        
        // Normalize the point.
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridian(of: point) as! AGSPoint
        
        // Cancel all previous operations.
        if self.locatorTaskOperation != nil {
            self.locatorTaskOperation.cancel()
        }
        
        // Create a graphic and add to the overlay.
        let graphic = self.makeGraphic(point: normalizedPoint)
        self.graphicsOverlay.graphics.add(graphic)
        
        // Initialize reverse geocode parameters.
        let reverseGeocodeParameters = AGSReverseGeocodeParameters()
        reverseGeocodeParameters.maxResults = 1
        reverseGeocodeParameters.resultAttributeNames.append(contentsOf: ["*"])
        // Perform reverse geocode.
        self.locatorTaskOperation = self.locatorTask.reverseGeocode(withLocation: normalizedPoint, parameters: reverseGeocodeParameters) { [weak self] (results: [AGSGeocodeResult]?, error: Error?) in
            if let error = error as NSError? {
                if error.code != NSUserCancelledError {
                    // Print error instead alerting to avoid disturbing the flow.
                    print(error.localizedDescription)
                }
            } else if let result = results?.first {
                // If a result is found, extract the required attributes.
                // Assign the attributes to the graphic
                // and show the callout.
                let cityString = result.attributes?["City"] as? String ?? ""
                let streetString = result.attributes?["StAddr"] as? String ?? ""
                let stateString = result.attributes?["Region"] as? String ?? ""
                graphic.attributes.addEntries(from: ["Match_addr": "\(streetString), \(cityString), \(stateString)"])
                self?.showCalloutForGraphic(graphic, tapLocation: normalizedPoint, animated: false, offset: self!.longPressedAndMoving)
                return
            } else {
                // If no result was found print in log instead of alert to avoid breaking the flow.
                print("No address found")
                
                // Dismiss the callout if already visible.
                self?.mapView.callout.dismiss()
            }
            // In case of error or no results, remove the graphics.
            self?.graphicsOverlay.graphics.remove(graphic)
        }
    }
    
    /// Method returns a graphic object for the point and attributes provided.
    private func makeGraphic(point: AGSPoint, attributes: [String: Any]? = nil) -> AGSGraphic {
        let markerImage = #imageLiteral(resourceName: "RedMarker")
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height / 2
        symbol.offsetY = markerImage.size.height / 2
        return AGSGraphic(geometry: point, symbol: symbol, attributes: attributes)
    }
    
    /// Method to show the callout for the provided graphic, with tap location details.
    private func showCalloutForGraphic(_ graphic: AGSGraphic, tapLocation: AGSPoint, animated: Bool, offset: Bool) {
        self.mapView.callout.title = graphic.attributes["Match_addr"] as? String
        self.mapView.callout.isAccessoryButtonHidden = true
        
        // Configure the magnifier graphics.
        let img = UIImage(named: "Magnifier", in: AGSBundle(), compatibleWith: nil)!
        // The total amount by which we will need to offset the callout along y-axis
        // to show it correctly centered on the pushpin's head in the magnifier.
        let magnifierOffset = CGPoint(x: 0, y: -img.size.height)
        if !offset {
            self.mapView.callout.show(for: graphic, tapLocation: tapLocation, animated: animated)
        } else {
            self.mapView.callout.show(at: tapLocation, screenOffset: magnifierOffset, rotateOffsetWithMap: false, animated: animated)
        }
    }
    
    // MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Dismiss the callout if already visible.
        self.mapView.callout.dismiss()
        
        // Get the graphics at the tap location.
        self.mapView.identify(self.graphicsOverlay, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 1) { (result: AGSIdentifyGraphicsOverlayResult) in
            if let error = result.error {
                self.presentAlert(error: error)
            } else if let graphic = result.graphics.first {
                // Show the callout for the first graphic found.
                self.showCalloutForGraphic(graphic, tapLocation: mapPoint, animated: true, offset: false)
            }
        }
    }
    
    func geoView(_ geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.longPressedAndMoving = true
        // On long press, perform reverse geocode.
        self.reverseGeocode(point: mapPoint)
    }
    
    func geoView(_ geoView: AGSGeoView, didMoveLongPressToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Perform geocode for the updated location.
        self.reverseGeocode(point: mapPoint)
    }
    
    func geoView(_ geoView: AGSGeoView, didEndLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.longPressedAndMoving = false
        // Update the callout to show on top of the graphic.
        self.mapView.touchDelegate?.geoView!(self.mapView, didTapAtScreenPoint: screenPoint, mapPoint: mapPoint)
    }
    
    // MARK: - UISearchBar delegates
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.geocodeSearchText(searchBar.text!)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.graphicsOverlay.graphics.removeAllObjects()
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
            let controller = segue.destination as! SanDiegoAddressesViewController
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
    
    // MARK: - SanDiegoAddressesViewControllerDelegate
    
    /// When the user selects an address from the list, update the search bar text, geocode the selected address.
    func sanDiegoAddressesViewController(_ sanDiegoAddressesViewController: SanDiegoAddressesViewController, didSelectAddress address: String) {
        self.searchBar.text = address
        self.geocodeSearchText(address)
        self.dismiss(animated: true)
    }
}
