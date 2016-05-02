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

class FindAddressViewController: UIViewController, AGSMapViewTouchDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, WorldAddressesVCDelegate {
    
    @IBOutlet private var mapView:AGSMapView!
    @IBOutlet private var button:UIButton!
    @IBOutlet private var searchBar:UISearchBar!
    
    private var locatorTask:AGSLocatorTask!
    private var geocodeParameters:AGSGeocodeParameters!
    private var graphicsOverlay:AGSGraphicsOverlay!
    
    private let locatorURL = "http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FindAddressViewController", "WorldAddressesViewController"]
        
        //instantiate a map with an imagery with labels basemap
        let map = AGSMap(basemap: AGSBasemap.imageryWithLabelsBasemap())
        self.mapView.map = map
        self.mapView.touchDelegate = self
        
        //initialize the graphics overlay and add to the map view
        self.graphicsOverlay = AGSGraphicsOverlay()
        self.mapView.graphicsOverlays.addObject(self.graphicsOverlay)
        
        //initialize locator task
        self.locatorTask = AGSLocatorTask(URL: NSURL(string: self.locatorURL)!)
        
        //initialize geocode parameters
        self.geocodeParameters = AGSGeocodeParameters()
        self.geocodeParameters.resultAttributeNames.appendContentsOf(["*"])
        self.geocodeParameters.minScore = 75
        
        //register self for the keyboard show notification
        //in order to un hide the cancel button for search
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FindAddressViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
    }
    
    //method that returns a graphic object for the specified point and attributes
    //also sets the leader offset and offset
    private func graphicForPoint(point: AGSPoint, attributes: [String: AnyObject]?) -> AGSGraphic {
        let markerImage = UIImage(named: "RedMarker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height/2
        symbol.offsetY = markerImage.size.height/2
        let graphic = AGSGraphic(geometry: point, attributes: attributes, symbol: symbol)
        return graphic
    }
    
    private func geocodeSearchText(text:String) {
        //clear already existing graphics
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //dismiss the callout if already visible
        self.mapView.callout.dismiss()
        
        //TODO: remove loadWithCompletion for locatorTask
        self.locatorTask.loadWithCompletion { (error) -> Void in
            //perform geocode with input text
            self.locatorTask.geocodeWithSearchText(text, parameters: self.geocodeParameters, completion: { [weak self] (results:[AGSGeocodeResult]?, error:NSError?) -> Void in
                if let error = error {
                    self?.showAlert(error.localizedDescription)
                }
                else {
                    if let results = results where results.count > 0 {
                        //create a graphic for the first result and add to the graphics overlay
                        let graphic = self?.graphicForPoint(results[0].displayLocation!, attributes: results[0].attributes)
                        self?.graphicsOverlay.graphics.addObject(graphic!)
                        //zoom to the extent of the graphic to highlight the result
                        self?.mapView.setViewpointGeometry(results[0].displayLocation!.extent, completion: nil)
                    }
                    else {
                        //provide feedback in case of failure
                        self?.showAlert("No results found")
                    }
                }
            })
        }
    }
    
    //MARK: - Callout
    
    //method shows the callout for the specified graphic,
    //populates the title and detail of the callout with specific attributes
    //hides the accessory button
    private func showCalloutForGraphic(graphic:AGSGraphic, tapLocation:AGSPoint) {
        let addressType = graphic.attributeValueForKey("Addr_type") as! String
        self.mapView.callout.title = graphic.attributeValueForKey("Match_addr") as? String ?? ""
        
        if addressType == "POI" {
            self.mapView.callout.detail = graphic.attributeValueForKey("Place_addr") as? String ?? ""
        }
        else {
            self.mapView.callout.detail = nil
        }
        
        self.mapView.callout.accessoryButtonHidden = true
        self.mapView.callout.showCalloutForGraphic(graphic, overlay: self.graphicsOverlay, tapLocation: tapLocation, animated: true)
    }
    
    private func showAlert(message:String) {
        UIAlertView(title: "Error", message: message, delegate: nil, cancelButtonTitle: "Ok").show()
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView, didTapAtScreenPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        //dismiss the callout
        self.mapView.callout.dismiss()
        
        //identify graphics at the tapped location
        self.mapView.identifyGraphicsOverlay(self.graphicsOverlay, screenPoint: screen, tolerance: 5, maximumResults: 1) { (graphics: [AGSGraphic]?, error: NSError?) -> Void in
            if let error = error {
                self.showAlert(error.localizedDescription)
            }
            else if let graphics = graphics where graphics.count > 0 {
                //show callout for the graphic
                self.showCalloutForGraphic(graphics[0], tapLocation: mappoint)
            }
        }
    }
    
    //MARK: - UISearchBar delegates
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.geocodeSearchText(searchBar.text!)
        self.hideKeyboard()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            self.graphicsOverlay.graphics.removeAllObjects()
            self.mapView.callout.dismiss()
        }
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
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "AddressesListSegue" {
            let controller = segue.destinationViewController as! WorldAddressesViewController
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
    
    //MARK: - AddressesListVCDelegate
    
    func worldAddressesViewController(worldAddressesViewController: WorldAddressesViewController, didSelectAddress address: String) {
        self.searchBar.text = address
        self.geocodeSearchText(address)
        self.dismissViewControllerAnimated(true, completion: nil)
        self.hideKeyboard()
    }
}
