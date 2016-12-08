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
        let path = NSBundle.mainBundle().pathForResource("streetmap_SD", ofType: "tpk")!
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(fileURL: NSURL(fileURLWithPath: path)))
        
        //instantiate map and add the local tiled layer
        let map = AGSMap()
        map.operationalLayers.addObject(localTiledLayer)
        
        //assign the map to the map view
        self.mapView.map = map
        //register self as the touch delgate for the map view
        //will need that to show callout
        self.mapView.touchDelegate = self
        
        //initialize the graphics overlay and add to the map view
        //will add the resulting graphics to this overlay
        self.graphicsOverlay = AGSGraphicsOverlay()
        self.mapView.graphicsOverlays.addObject(self.graphicsOverlay)
        
        //initialize locator task
        self.locatorTask = AGSLocatorTask(name: "san-diego-locator")
        
        //initialize geocode params
        self.geocodeParameters = AGSGeocodeParameters()
        self.geocodeParameters.resultAttributeNames.appendContentsOf(["Match_addr"])
        self.geocodeParameters.minScore = 75
        
        //initialize reverse geocode params
        self.reverseGeocodeParameters = AGSReverseGeocodeParameters()
        self.reverseGeocodeParameters.maxResults = 1
        self.reverseGeocodeParameters.resultAttributeNames.appendContentsOf(["*"])
        
        //add self as the observer for the keyboard show notification
        //will display a button every time keyboard is display so the user
        //can tap and cancel search and hide the keyboard
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GeocodeOfflineViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        
        //zoom to San Diego
        self.mapView.setViewpointCenter(AGSPoint(x: -13042254.715252, y: 3857970.236806, spatialReference: AGSSpatialReference(WKID: 3857)), scale: 2e4, completion: nil)
        
        //enable magnifier for better experience while using tap n hold to add a location
        self.mapView.interactionOptions.magnifierEnabled = true
        
        //the total amount by which we will need to offset the callout along y-axis
        //to show it correctly centered on the pushpin's head in the magnifier
        let img = UIImage(named: "ArcGIS.bundle/Magnifier.png")!
        self.magnifierOffset = CGPoint(x: 0, y: -img.size.height)
    }
    
    private func geocodeSearchText(text:String) {
        //hide keyboard
        self.hideKeyboard()
        
        //dismiss the callout if already visible
        self.mapView.callout.dismiss()
        
        //remove all previous graphics
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //perform geocode with the input
        self.locatorTask.geocodeWithSearchText(text, parameters: self.geocodeParameters, completion: { [weak self]  (results:[AGSGeocodeResult]?, error:NSError?) -> Void in
            if let error = error {
                self?.showAlert(error.localizedDescription)
            }
            else {
                //if a result was returned display the graphic on the map view
                //using the first result, as it is the more relevant
                if let results = results where results.count > 0 {
                    let graphic = self?.graphicForPoint(results[0].displayLocation!, attributes: results[0].attributes)
                    self?.graphicsOverlay.graphics.addObject(graphic!)
                    
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
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridianOfGeometry(point) as! AGSPoint
        
        //cancel all previous operations
        if self.locatorTaskOperation != nil {
            self.locatorTaskOperation.cancel()
        }
        
        //create a graphic and add to the overlay
        let graphic = self.graphicForPoint(normalizedPoint, attributes: [String:AnyObject]())
        self.graphicsOverlay.graphics.addObject(graphic)
        
        //perform reverse geocode
        self.locatorTaskOperation = self.locatorTask.reverseGeocodeWithLocation(normalizedPoint, parameters: self.reverseGeocodeParameters) { [weak self] (results: [AGSGeocodeResult]?, error: NSError?) -> Void in

            if let error = error where error.code != NSUserCancelledError {
                //print error instead alerting to avoid disturbing the flow
                print(error.localizedDescription)
            }
            else {
                //if a result is found extract the required attributes
                //assign the attributes to the graphic
                //and show the callout
                if let results = results where results.count > 0 {
                    let cityString = results.first?.attributes?["City"] as? String ?? ""
                    let streetString = results.first?.attributes?["Street"] as? String ?? ""
                    let stateString = results.first?.attributes?["State"] as? String ?? ""
                    graphic.attributes.addEntriesFromDictionary(["Match_addr":"\(streetString) \(cityString) \(stateString)"])
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
            self?.graphicsOverlay.graphics.removeObject(graphic)
        }
    }
    
    //method returns a graphic object for the point and attributes provided
    private func graphicForPoint(point: AGSPoint, attributes: [String: AnyObject]?) -> AGSGraphic {
        let markerImage = UIImage(named: "RedMarker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height/2
        symbol.offsetY = markerImage.size.height/2
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: attributes)
        return graphic
    }
    
    //method to show the callout for the provided graphic, with tap location details
    private func showCalloutForGraphic(graphic:AGSGraphic, tapLocation:AGSPoint, animated:Bool, offset:Bool) {
        self.mapView.callout.title = graphic.attributes["Match_addr"] as? String
        self.mapView.callout.accessoryButtonHidden = true
        
        if !offset {
            self.mapView.callout.showCalloutForGraphic(graphic, tapLocation: tapLocation, animated: animated)
        }
        else {
            self.mapView.callout.showCalloutAt(tapLocation, screenOffset: self.magnifierOffset, rotateOffsetWithMap: false, animated: animated)
        }
    }
    
    private func showAlert(message:String) {
        SVProgressHUD.showErrorWithStatus(message, maskType: .Gradient)
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //dismiss the callout if already visible
        self.mapView.callout.dismiss()
        
        //get the graphics at the tap location
        self.mapView.identifyGraphicsOverlay(self.graphicsOverlay, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 1) { (result: AGSIdentifyGraphicsOverlayResult) -> Void in

            if let error = result.error {
                self.showAlert(error.localizedDescription)
            }
            else if result.graphics.count > 0 {
                //show the callout for the first graphic found
                self.showCalloutForGraphic(result.graphics.first!, tapLocation: mapPoint, animated: true, offset: false)
            }
        }
    }
    
    func geoView(geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.longPressedAndMoving = true
        //on long press perform reverse geocode
        self.reverseGeocode(mapPoint)
    }
    
    func geoView(geoView: AGSGeoView, didMoveLongPressToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //perform geocode for the updated location
        self.reverseGeocode(mapPoint)
    }
    
    func geoView(geoView: AGSGeoView, didEndLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        self.longPressedAndMoving = false
        //the callout right now will be at an offset
        //update the callout to show on top of the graphic
        self.mapView.touchDelegate?.geoView!(self.mapView, didTapAtScreenPoint: screenPoint, mapPoint: mapPoint)
    }
    
    //MARK: - UISearchBar delegates
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.geocodeSearchText(searchBar.text!)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.graphicsOverlay.graphics.removeAllObjects()
    }
    
    func searchBarResultsListButtonClicked(searchBar: UISearchBar) {
        self.performSegueWithIdentifier("AddressesListSegue", sender: self)
    }
    
    //MARK: - Actions
    func keyboardWillShow(sender:AnyObject) {
        self.button.hidden = false
    }
    
    @IBAction func hideKeyboard() {
        self.searchBar.resignFirstResponder()
        self.button.hidden = true
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddressesListSegue" {
            let controller = segue.destinationViewController as! SanDiegoAddressesViewController
            controller.presentationController?.delegate = self
            controller.popoverPresentationController?.sourceView = self.view
            controller.popoverPresentationController?.sourceRect = self.searchBar.frame
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            controller.delegate = self
        }
    }
    
    //MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.None
    }
    
    //MARK: - SanDiegoAddressesVCDelegate
    
    //when the user selects an address from the list
    //update the search bar text, geocode the selected address
    func sanDiegoAddressesViewController(sanDiegoAddressesViewController: SanDiegoAddressesViewController, didSelectAddress address: String) {
        self.searchBar.text = address
        self.geocodeSearchText(address)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
