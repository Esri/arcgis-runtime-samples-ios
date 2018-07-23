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

class GeocodeOfflineViewController: UIViewController, AGSGeoViewTouchDelegate, UISearchBarDelegate, UIAdaptivePresentationControllerDelegate, SanDiegoAddressesVCDelegate {
    
    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var button:UIButton!
    @IBOutlet private var searchBar:UISearchBar!
    
    private var locatorTask:AGSLocatorTask!
    private var geocodeParameters:AGSGeocodeParameters!
    private var reverseGeocodeParameters:AGSReverseGeocodeParameters!
    private var graphicsOverlay:AGSGraphicsOverlay!
    private var locatorTaskOperation:AGSCancelable!
    private var magnifierOffset:CGPoint!
    private var longPressedAndMoving = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OfflineGeocodeViewController", "SanDiegoAddressesViewController"]
        
        //create a local tiled layer using tile package
        let path = Bundle.main.path(forResource: "streetmap_SD", ofType: "tpk")!
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(fileURL: URL(fileURLWithPath: path)))
        
        //instantiate map and add the local tiled layer
        let map = AGSMap()
        map.operationalLayers.add(localTiledLayer)
        
        //assign the map to the map view
        self.mapView.map = map
        //register self as the touch delgate for the map view
        //will need that to show callout
        self.mapView.touchDelegate = self
        
        //initialize the graphics overlay and add to the map view
        //will add the resulting graphics to this overlay
        self.graphicsOverlay = AGSGraphicsOverlay()
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        //initialize locator task
        self.locatorTask = AGSLocatorTask(name: "san-diego-locator")
        
        //initialize geocode params
        self.geocodeParameters = AGSGeocodeParameters()
        self.geocodeParameters.resultAttributeNames.append(contentsOf: ["Match_addr"])
        self.geocodeParameters.minScore = 75
        
        //initialize reverse geocode params
        self.reverseGeocodeParameters = AGSReverseGeocodeParameters()
        self.reverseGeocodeParameters.maxResults = 1
        self.reverseGeocodeParameters.resultAttributeNames.append(contentsOf: ["*"])
        
        //add self as the observer for the keyboard show notification
        //will display a button every time keyboard is display so the user
        //can tap and cancel search and hide the keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(GeocodeOfflineViewController.keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        
        //zoom to San Diego
        self.mapView.setViewpointCenter(AGSPoint(x: -13042254.715252, y: 3857970.236806, spatialReference: AGSSpatialReference(wkid: 3857)), scale: 2e4, completion: nil)
        
        //enable magnifier for better experience while using tap n hold to add a location
        self.mapView.interactionOptions.isMagnifierEnabled = true
        
        //the total amount by which we will need to offset the callout along y-axis
        //to show it correctly centered on the pushpin's head in the magnifier
        let img = UIImage(named: "ArcGIS.bundle/Magnifier.png")!
        self.magnifierOffset = CGPoint(x: 0, y: -img.size.height)
    }
    
    private func geocodeSearchText(_ text:String) {
        //hide keyboard
        self.hideKeyboard()
        
        //dismiss the callout if already visible
        self.mapView.callout.dismiss()
        
        //remove all previous graphics
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //perform geocode with the input
        self.locatorTask.geocode(withSearchText: text, parameters: self.geocodeParameters, completion: { [weak self]  (results:[AGSGeocodeResult]?, error:Error?) -> Void in
            if let error = error {
                self?.showAlert(error.localizedDescription)
            }
            else {
                //if a result was returned display the graphic on the map view
                //using the first result, as it is the more relevant
                if let results = results , results.count > 0 {
                    let graphic = self?.graphicForPoint(results[0].displayLocation!, attributes: results[0].attributes as [String : AnyObject]?)
                    self?.graphicsOverlay.graphics.add(graphic!)
                    
                    //zoom to the extent of the graphic
                    self?.mapView.setViewpointGeometry(results[0].displayLocation!.extent, completion: nil)
                }
                else {
                    //if no result found, inform the user
                    self?.showAlert("No results found")
                }
            }
        })
    }
    
    private func reverseGeocode(point:AGSPoint) {
        //clear the search bar text to give feedback that the graphic
        //is based on the tap and not search
        self.searchBar.text = ""
        
        //remove all previous graphics
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //normalize the point
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridian(of: point) as! AGSPoint
        
        //cancel all previous operations
        if self.locatorTaskOperation != nil {
            self.locatorTaskOperation.cancel()
        }
        
        //create a graphic and add to the overlay
        let graphic = self.graphicForPoint(normalizedPoint, attributes: [String:AnyObject]())
        self.graphicsOverlay.graphics.add(graphic)
        
        //perform reverse geocode
        self.locatorTaskOperation = self.locatorTask.reverseGeocode(withLocation: normalizedPoint, parameters: self.reverseGeocodeParameters) { [weak self] (results: [AGSGeocodeResult]?, error: Error?) -> Void in

            if let error = error as NSError? , error.code != NSUserCancelledError {
                //print error instead alerting to avoid disturbing the flow
                print(error.localizedDescription)
            }
            else {
                //if a result is found extract the required attributes
                //assign the attributes to the graphic
                //and show the callout
                if let results = results , results.count > 0 {
                    let cityString = results.first?.attributes?["City"] as? String ?? ""
                    let streetString = results.first?.attributes?["Street"] as? String ?? ""
                    let stateString = results.first?.attributes?["State"] as? String ?? ""
                    graphic.attributes.addEntries(from: ["Match_addr":"\(streetString) \(cityString) \(stateString)"])
                    self?.showCalloutForGraphic(graphic, tapLocation: normalizedPoint, animated: false, offset: self!.longPressedAndMoving)
                    return
                }
                else {
                    //no result was found
                    //using print in log instead of alert to
                    //avoid breaking the flow
                    print("No address found")

                    //dismiss the callout if already visible
                    self?.mapView.callout.dismiss()

                }
            }
            //in case of error or no results, remove the graphics
            self?.graphicsOverlay.graphics.remove(graphic)
        }
    }
    
    //method returns a graphic object for the point and attributes provided
    private func graphicForPoint(_ point: AGSPoint, attributes: [String: AnyObject]?) -> AGSGraphic {
        let markerImage = UIImage(named: "RedMarker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height/2
        symbol.offsetY = markerImage.size.height/2
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: attributes)
        return graphic
    }
    
    //method to show the callout for the provided graphic, with tap location details
    private func showCalloutForGraphic(_ graphic:AGSGraphic, tapLocation:AGSPoint, animated:Bool, offset:Bool) {
        self.mapView.callout.title = graphic.attributes["Match_addr"] as? String
        self.mapView.callout.isAccessoryButtonHidden = true
        
        if !offset {
            self.mapView.callout.show(for: graphic, tapLocation: tapLocation, animated: animated)
        }
        else {
            self.mapView.callout.show(at: tapLocation, screenOffset: self.magnifierOffset, rotateOffsetWithMap: false, animated: animated)
        }
    }
    
    private func showAlert(_ message:String) {
        SVProgressHUD.showError(withStatus: message)
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //dismiss the callout if already visible
        self.mapView.callout.dismiss()
        
        //get the graphics at the tap location
        self.mapView.identify(self.graphicsOverlay, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 1) { (result: AGSIdentifyGraphicsOverlayResult) -> Void in

            if let error = result.error {
                self.showAlert(error.localizedDescription)
            }
            else if result.graphics.count > 0 {
                //show the callout for the first graphic found
                self.showCalloutForGraphic(result.graphics.first!, tapLocation: mapPoint, animated: true, offset: false)
            }
        }
    }
    
    func geoView(_ geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.longPressedAndMoving = true
        //on long press perform reverse geocode
        self.reverseGeocode(point: mapPoint)
    }
    
    func geoView(_ geoView: AGSGeoView, didMoveLongPressToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //perform geocode for the updated location
        self.reverseGeocode(point: mapPoint)
    }
    
    func geoView(_ geoView: AGSGeoView, didEndLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.longPressedAndMoving = false
        //the callout right now will be at an offset
        //update the callout to show on top of the graphic
        self.mapView.touchDelegate?.geoView!(self.mapView, didTapAtScreenPoint: screenPoint, mapPoint: mapPoint)
    }
    
    //MARK: - UISearchBar delegates
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.geocodeSearchText(searchBar.text!)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.graphicsOverlay.graphics.removeAllObjects()
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
    
    //MARK: - Navigation
    
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
    
    //MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.none
    }
    
    //MARK: - SanDiegoAddressesVCDelegate
    
    //when the user selects an address from the list
    //update the search bar text, geocode the selected address
    func sanDiegoAddressesViewController(_ sanDiegoAddressesViewController: SanDiegoAddressesViewController, didSelectAddress address: String) {
        self.searchBar.text = address
        self.geocodeSearchText(address)
        self.dismiss(animated: true, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
