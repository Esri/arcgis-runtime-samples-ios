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

class GeocodeOfflineViewController: UIViewController, AGSMapViewTouchDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, SanDiegoAddressesVCDelegate {
    
    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var button:UIButton!
    @IBOutlet private var searchBar:UISearchBar!
    
    private var locatorTask:AGSLocatorTask!
    private var geocodeParameters:AGSGeocodeParameters!
    private var reverseGeocodeParameters:AGSReverseGeocodeParameters!
    private var graphicsOverlay:AGSGraphicsOverlay!
    private var locatorTaskOperation:AGSCancellable!
    
    private let locatorURL = "http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["OfflineGeocodeViewController", "SanDiegoAddressesViewController"]
        
        //create a local tiled layer using tile package
        let path = NSBundle.mainBundle().pathForResource("streetmap_SD", ofType: "tpk")!
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(path: path))
        
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        
        //zoom to San Diego
        self.mapView.setViewpointCenter(AGSPoint(x: -13042254.715252, y: 3857970.236806, spatialReference: AGSSpatialReference(WKID: 3857)), scale: 2e4, completion: nil)
    }
    
    private func geocodeSearchText(text:String) {
        //hide keyboard
        self.hideKeyboard()
        
        //dismiss the callout if already visible
        self.mapView.callout.dismiss()
        
        //remove all previous graphics
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //TODO: remove loadWithCompletion for locatorTask
        self.locatorTask.loadWithCompletion { (error) -> Void in
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
        let graphic = self.graphicForPoint(normalizedPoint, attributes: nil)
        self.graphicsOverlay.graphics.addObject(graphic)
        
        //TODO: remove loadWithCompletion for locatorTask
        self.locatorTask.loadWithCompletion { [weak self] (error:NSError?) -> Void in
            //perform reverse geocode
            self?.locatorTaskOperation = self!.locatorTask.reverseGeocodeWithLocation(normalizedPoint, parameters: self!.reverseGeocodeParameters) { (results: [AGSGeocodeResult]?, error: NSError?) -> Void in
                if let error = error {
                    self?.showAlert(error.localizedDescription)
                }
                else {
                    //if a result is found extract the required attributes
                    //assign the attributes to the graphic
                    //and show the callout
                    if let results = results where results.count > 0 {
                        let cityString = results.first?.attributes?["City"] as? String ?? ""
                        let streetString = results.first?.attributes?["Street"] as? String ?? ""
                        let stateString = results.first?.attributes?["State"] as? String ?? ""
                        graphic.attributes = ["Match_addr":"\(streetString) \(cityString) \(stateString)"]
                        self?.showCalloutForGraphic(graphic, tapLocation: normalizedPoint, animated: false)
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
    }
    
    //method returns a graphic object for the point and attributes provided
    private func graphicForPoint(point: AGSPoint, attributes: [String: AnyObject]?) -> AGSGraphic {
        let markerImage = UIImage(named: "RedMarker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height/2
        symbol.offsetY = markerImage.size.height/2
        let graphic = AGSGraphic(geometry: point, attributes: attributes, symbol: symbol)
        return graphic
    }
    
    //method to show the callout for the provided graphic, with tap location details
    private func showCalloutForGraphic(graphic:AGSGraphic, tapLocation:AGSPoint, animated:Bool) {
        self.mapView.callout.title = graphic.attributeValueForKey("Match_addr") as? String
        self.mapView.callout.accessoryButtonHidden = true
        self.mapView.callout.showCalloutForGraphic(graphic, overlay: self.graphicsOverlay, tapLocation: tapLocation, animated: animated)
    }
    
    private func showAlert(message:String) {
        UIAlertView(title: "Error", message: message, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView, didTapAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        //dismiss the callout if already visible
        self.mapView.callout.dismiss()
        
        //get the graphics at the tap location
        self.mapView.identifyGraphicsOverlay(self.graphicsOverlay, screenPoint: screen, tolerance: 5, maximumResults: 1) { (graphics: [AGSGraphic]?, error: NSError?) -> Void in
            if let error = error {
                self.showAlert(error.localizedDescription)
            }
            else if let graphics = graphics where graphics.count > 0 {
                //show the callout for the first graphic found
                self.showCalloutForGraphic(graphics.first!, tapLocation: mappoint, animated: true)
            }
        }
    }
    
    func mapView(mapView: AGSMapView, didLongPressAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        //on long press perform reverse geocode
        self.reverseGeocode(mappoint)
    }
    
    func mapView(mapView: AGSMapView, didMoveLongPressToPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        //perform geocode for the updated location
        self.reverseGeocode(mappoint)
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
            controller.popoverPresentationController?.delegate = self
            controller.popoverPresentationController?.sourceView = self.view
            controller.popoverPresentationController?.sourceRect = self.searchBar.frame
            controller.preferredContentSize = CGSize(width: 300, height: 200)
            controller.delegate = self
        }
    }
    
    //MARK: - UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
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
