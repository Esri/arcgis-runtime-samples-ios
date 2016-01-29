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
        
        let path = NSBundle.mainBundle().pathForResource("streetmap_SD", ofType: "tpk")!
        let localTiledLayer = AGSArcGISTiledLayer(tileCache: AGSTileCache(path: path))
        
        let map = AGSMap()
        map.operationalLayers.addObject(localTiledLayer)
        
        self.mapView.map = map
        self.mapView.touchDelegate = self
        
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
    }
    
    private func geocodeSearchText(text:String) {
        //hide keyboard
        self.hideKeyboard()
        
        self.mapView.callout.dismiss()
        
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //TODO: remove loadWithCompletion for locatorTask
        self.locatorTask.loadWithCompletion { (error) -> Void in
            self.locatorTask.geocodeWithSearchText(text, parameters: self.geocodeParameters, completion: { [weak self]  (results:[AGSGeocodeResult]?, error:NSError?) -> Void in
                if let error = error {
                    self?.showAlert(error.localizedDescription)
                }
                else {
                    if let results = results where results.count > 0 {
                        let graphic = self?.graphicForPoint(results[0].displayLocation!, attributes: results[0].attributes)
                        self?.graphicsOverlay.graphics.addObject(graphic!)
                        self?.zoomToGraphics(self!.graphicsOverlay.graphics.array as! [AGSGraphic])
                    }
                    else {
                        self?.showAlert("No results found")
                    }
                }
            })
        }
    }
    
    private func reverseGeocode(point:AGSPoint) {
        self.searchBar.text = ""
        
        self.mapView.callout.dismiss()
        self.graphicsOverlay.graphics.removeAllObjects()
        
        let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridianOfGeometry(point) as! AGSPoint
        
        if self.locatorTaskOperation != nil {
            self.locatorTaskOperation.cancel()
        }
        
        let graphic = self.graphicForPoint(normalizedPoint, attributes: nil)
        self.graphicsOverlay.graphics.addObject(graphic)
        
        //TODO: remove loadWithCompletion for locatorTask
        self.locatorTask.loadWithCompletion { [weak self] (error:NSError?) -> Void in
            
            self?.locatorTaskOperation = self!.locatorTask.reverseGeocodeWithLocation(normalizedPoint, parameters: self!.reverseGeocodeParameters) { (results: [AGSGeocodeResult]?, error: NSError?) -> Void in
                if let error = error {
                    self?.showAlert(error.localizedDescription)
                }
                else {
                    if let results = results where results.count > 0 {
                        let cityString = results.first?.attributes?["City"] as? String ?? ""
                        let streetString = results.first?.attributes?["Street"] as? String ?? ""
                        let stateString = results.first?.attributes?["State"] as? String ?? ""
                        graphic.attributes = ["Match_addr":"\(streetString) \(cityString) \(stateString)"]
                        self?.showCalloutForGraphic(graphic, tapLocation: normalizedPoint, animated: false)
                        return
                    }
                    else {
                        //                        self?.showAlert("No address found")
                        print("No address found")
                    }
                }
                self?.graphicsOverlay.graphics.removeObject(graphic)
            }
        }
    }
    
    func graphicForPoint(point: AGSPoint, attributes: [String: AnyObject]?) -> AGSGraphic {
        let markerImage = UIImage(named: "RedMarker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height/2
        symbol.offsetY = markerImage.size.height/2
        let graphic = AGSGraphic(geometry: point, attributes: attributes, symbol: symbol)
        return graphic
    }
    
    func zoomToGraphics(graphics:[AGSGraphic]) {
        if graphics.count > 0 {
            let multipoint = AGSMultipointBuilder(spatialReference: graphics[0].geometry!.spatialReference)
            for graphic in graphics {
                multipoint.points.addPoint(graphic.geometry as! AGSPoint)
            }
            self.mapView.setViewpoint(AGSViewpoint(targetExtent: multipoint.extent), completion: { (finished:Bool) -> Void in
            })
        }
    }
    
    func showCalloutForGraphic(graphic:AGSGraphic, tapLocation:AGSPoint, animated:Bool) {
        self.mapView.callout.title = graphic.attributeValueForKey("Match_addr") as? String
        self.mapView.callout.accessoryButtonHidden = true
        self.mapView.callout.showCalloutForGraphic(graphic, overlay: self.graphicsOverlay, tapLocation: tapLocation, animated: animated)
    }
    
    private func showAlert(message:String) {
        UIAlertView(title: "Error", message: message, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView, didTapAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        //dismiss the callout
        self.mapView.callout.dismiss()
        
        self.mapView.identifyGraphicsOverlay(self.graphicsOverlay, screenCoordinate: screen, tolerance: 44, maximumResults: 1) { (graphics: [AGSGraphic]?, error: NSError?) -> Void in
            if let error = error {
                self.showAlert(error.localizedDescription)
            }
            else if let graphics = graphics where graphics.count > 0 {
                //normalize the tap point
                let normalizedPoint = AGSGeometryEngine.normalizeCentralMeridianOfGeometry(mappoint) as! AGSPoint
                self.showCalloutForGraphic(graphics.first!, tapLocation: normalizedPoint, animated: true)
            }
        }
    }
    
    func mapView(mapView: AGSMapView, didLongPressAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        self.reverseGeocode(mappoint)
    }
    
    func mapView(mapView: AGSMapView, didMoveLongPressToPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
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
    
    func sanDiegoAddressesViewController(sanDiegoAddressesViewController: SanDiegoAddressesViewController, didSelectAddress address: String) {
        self.searchBar.text = address
        self.geocodeSearchText(address)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
