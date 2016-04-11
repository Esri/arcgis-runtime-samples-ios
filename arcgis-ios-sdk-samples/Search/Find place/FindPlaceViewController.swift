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

enum SuggestionType {
    case POI
    case PopulatedPlace
}

class FindPlaceViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, AGSMapViewTouchDelegate {
    
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var tableView:UITableView!
    @IBOutlet var preferredSearchLocationTextField:UITextField!
    @IBOutlet var poiTextField:UITextField!
    @IBOutlet var tableViewHeightConstraint:NSLayoutConstraint!
    @IBOutlet var extentSearchButton:UIButton!
    @IBOutlet var overlayView:UIView!
    
    private var textFieldLocationButton:UIButton!
    
    private var map:AGSMap!
    private var graphicsOverlay:AGSGraphicsOverlay!
    
    private var locatorTask:AGSLocatorTask!
    private var suggestResults:[AGSSuggestResult]!
    private var suggestRequestOperation:AGSCancellable!
    private var selectedSuggestResult:AGSSuggestResult!
    private var preferredSearchLocation:AGSPoint!
    private var selectedTextField:UITextField!
    
    private var isTableViewVisible = true
    private var isTableViewAnimating = false
    private var canDoExtentSearch = false {
        didSet {
            if !canDoExtentSearch {
                self.extentSearchButton.hidden = true
            }
        }
    }
    
    private var currentLocationText = "Current Location"
    private var isUsingCurrentLocation = false
    private let tableViewHeight:CGFloat = 120
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["FindPlaceViewController"]
        
        //create an instance of a map with ESRI topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.topographicBasemap())
        
        //assign the map to the map view
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
        //start location display
        self.mapView.locationDisplay.autoPanMode = .Default
        self.mapView.locationDisplay.startWithCompletion { [weak self] (error: NSError?) -> Void in
            if error == nil {
                //if the location display starts, update the preferred search location
                //textfield's text
                self?.preferredSearchLocationTextField.text = self!.currentLocationText
            }
        }
        
        //logic to show the extent search button
        self.mapView.viewpointChangedHandler = { [weak self] () -> Void in
            if self?.canDoExtentSearch ?? false {
                self?.extentSearchButton.hidden = false
            }
        }
        
        //instantiate the graphicsOverlay and add to the map view
        self.graphicsOverlay = AGSGraphicsOverlay()
        self.mapView.graphicsOverlays.addObject(self.graphicsOverlay)
        
        //initialize locator task
        self.locatorTask = AGSLocatorTask(URL: NSURL(string: "http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer")!)
        
        //hide suggest result table view by default
        self.animateTableView(false)
        
        //hide the overlay view by default
        self.overlayView.hidden = true
        
        //register for keyboard notification in order to toggle overlay view on and off
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FindPlaceViewController.showOverlayView), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FindPlaceViewController.hideOverlayView), name: UIKeyboardWillHideNotification, object: nil)
        
        //add the left view images for both the textfields
        self.setupTextFieldLeftViews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //method to show search icon and pin icon for the textfields
    private func setupTextFieldLeftViews() {
        var leftView = self.textFieldViewWithImage("SearchIcon")
        self.poiTextField.leftView = leftView
        self.poiTextField.leftViewMode = UITextFieldViewMode.Always
        
        leftView = self.textFieldViewWithImage("PinIcon")
        self.preferredSearchLocationTextField.leftView = leftView
        self.preferredSearchLocationTextField.leftViewMode = UITextFieldViewMode.Always
    }
    
    //method returns a UIView with an imageView as the subview
    //with an image instantiated using the name provided
    private func textFieldViewWithImage(imageName:String) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 30))
        let imageView = UIImageView(image: UIImage(named: imageName))
        imageView.frame = CGRect(x: 5, y: 5, width: 20, height: 20)
        view.addSubview(imageView)
        return view
    }
    
    //method to toggle the suggestions table view on and off
    private func animateTableView(expand:Bool) {
        if (expand != self.isTableViewVisible) && !self.isTableViewAnimating {
            self.isTableViewAnimating = true
            self.tableViewHeightConstraint.constant = expand ? self.tableViewHeight : 0
            UIView.animateWithDuration(0.1, animations: { [weak self] () -> Void in
                self?.view.layoutIfNeeded()
                }, completion: { [weak self] (finished) -> Void in
                    self?.isTableViewAnimating = false
                    self?.isTableViewVisible = expand
                })
        }
    }
    
    //method to clear prefered location information
    //hide the suggestions table view, empty previously selected
    //suggest result and previously fetch search location
    private func clearPreferredLocationInfo() {
        self.animateTableView(false)
        self.selectedSuggestResult = nil
        self.preferredSearchLocation = nil
    }
    
    //method to show callout for a graphic
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
    
    //method returns a graphic object for the specified point and attributes
    private func graphicForPoint(point: AGSPoint, attributes:[String:AnyObject]?) -> AGSGraphic {
        let markerImage = UIImage(named: "RedMarker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height/2
        symbol.offsetY = markerImage.size.height/2
        let graphic = AGSGraphic(geometry: point, attributes: attributes, symbol: symbol)
        return graphic
    }
    
    //method to zoom to an array of graphics
    func zoomToGraphics(graphics:[AGSGraphic]) {
        if graphics.count > 0 {
            let multipoint = AGSMultipointBuilder(spatialReference: graphics[0].geometry!.spatialReference)
            for graphic in graphics {
                multipoint.points.addPoint(graphic.geometry as! AGSPoint)
            }
            self.mapView.setViewpoint(AGSViewpoint(targetExtent: multipoint.extent), completion: { [weak self] (finished:Bool) -> Void in
                self?.canDoExtentSearch = true
            })
        }
    }
    
    //MARK: - AGSMapViewTouchDelegate
    
    func mapView(mapView: AGSMapView, didTapAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint) {
        //dismiss the callout if already visible
        self.mapView.callout.dismiss()
        
        //identify graphics at the tapped location
        self.mapView.identifyGraphicsOverlay(self.graphicsOverlay, screenPoint: screen, tolerance: 5, maximumResults: 1) { (graphics: [AGSGraphic]?, error: NSError?) -> Void in
            if let error = error {
                print(error)
            }
            else if let graphics = graphics where graphics.count > 0 {
                //show callout for the first graphic in the array
                self.showCalloutForGraphic(graphics[0], tapLocation: mappoint)
            }
        }
    }
    
    //MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 0
        if let count = self.suggestResults?.count {
            if self.selectedTextField == self.preferredSearchLocationTextField {
                rows = count + 1
            }
            else {
                rows = count
            }
        }
        self.animateTableView(rows > 0)
        return rows
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SuggestCell")!
        let isLocationTextField = (self.selectedTextField == self.preferredSearchLocationTextField)
        
        if isLocationTextField && indexPath.row == 0 {
            cell.textLabel?.text = self.currentLocationText
            cell.imageView?.image = UIImage(named: "CurrentLocationDisabledIcon")
            return cell
        }
        
        let rowNumber = isLocationTextField ? indexPath.row - 1 : indexPath.row
        let suggestResult = self.suggestResults[rowNumber]
        
        cell.textLabel?.text = suggestResult.label
        cell.imageView?.image = nil
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if self.selectedTextField == self.preferredSearchLocationTextField {
            if indexPath.row == 0 {
                self.preferredSearchLocationTextField.text = self.currentLocationText
            }
            else {
                let suggestResult = self.suggestResults[indexPath.row - 1]
                self.selectedSuggestResult = suggestResult
                self.preferredSearchLocation = nil
                self.selectedTextField.text = suggestResult.label
            }
        }
        else {
            let suggestResult = self.suggestResults[indexPath.row]
            self.selectedTextField.text = suggestResult.label
        }
        self.animateTableView(false)
    }
    
    //MARK: - UITextFieldDelegate
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        let newString = (textField.text! as NSString).stringByReplacingCharactersInRange(range, withString: string)
        
        if textField == self.preferredSearchLocationTextField {
            self.selectedTextField = self.preferredSearchLocationTextField
            if !newString.isEmpty {
                self.fetchSuggestions(newString, suggestionType: .PopulatedPlace, textField: self.preferredSearchLocationTextField)
            }
            self.clearPreferredLocationInfo()
        }
        else {
            self.selectedTextField = self.poiTextField
            if !newString.isEmpty {
                self.fetchSuggestions(newString, suggestionType: .POI, textField:self.poiTextField)
            }
            else {
                self.canDoExtentSearch = false
                self.animateTableView(false)
            }
        }
        return true
    }
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        if textField == self.preferredSearchLocationTextField {
            self.clearPreferredLocationInfo()
        }
        else {
            self.canDoExtentSearch = false
            self.animateTableView(false)
        }
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.search()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.animateTableView(false)
    }
    
    //MARK: - Suggestions logic
    
    private func fetchSuggestions(string:String, suggestionType:SuggestionType, textField:UITextField) {
        //cancel previous requests
        if self.suggestRequestOperation != nil {
            self.suggestRequestOperation.cancel()
        }
        
        //initialize suggest parameters
        let suggestParameters = AGSSuggestParameters()
        let flag:Bool = (suggestionType == SuggestionType.POI)
        suggestParameters.categories = flag ? ["POI"] : ["Populated Place"]
        suggestParameters.preferredSearchLocation = flag ? nil : self.mapView.locationDisplay.mapLocation
        
        //get suggestions
        self.suggestRequestOperation = self.locatorTask.suggestWithSearchText(string, parameters: suggestParameters) { (result: [AGSSuggestResult]?, error: NSError?) -> Void in
            if string == textField.text { //check if the search string has not changed in the meanwhile
                if let error = error {
                    print(error.localizedDescription)
                }
                else {
                    //update the suggest results and reload the table
                    self.suggestResults = result
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func geocodeUsingSuggestResult(suggestResult:AGSSuggestResult, completion: () -> Void) {
        //load locator task
        self.locatorTask.loadWithCompletion { [weak self] (error: NSError?) -> Void in
            if let error = error {
                print(error.localizedDescription)
            }
            
            //create geocode params
            let params = AGSGeocodeParameters()
            params.outputSpatialReference = self?.mapView.spatialReference
            
            //geocode with selected suggest result
            self?.locatorTask.geocodeWithSuggestResult(suggestResult, parameters: params) { (result: [AGSGeocodeResult]?, error: NSError?) -> Void in
                if let error = error {
                    print(error.localizedDescription)
                }
                else {
                    if let result = result where result.count > 0 {
                        self?.preferredSearchLocation = result[0].displayLocation
                        completion()
                    }
                    else {
                        print("No location found for the suggest result")
                    }
                }
            }
        }
    }
    
    private func geocodePOIs(poi:String, location:AGSPoint?, extent:AGSGeometry?) {
        //hide extent search button
        self.canDoExtentSearch = false
        self.extentSearchButton.hidden = true
        
        //remove all previous graphics
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //parameters for geocoding POIs
        let params = AGSGeocodeParameters()
        params.preferredSearchLocation = location
        params.searchArea = extent
        params.outputSpatialReference = self.mapView.spatialReference
        params.resultAttributeNames.appendContentsOf(["*"])
        
        //load the locatorTask
        self.locatorTask.loadWithCompletion { [weak self] (error) -> Void in
            
            //geocode using the search text and params
            self?.locatorTask.geocodeWithSearchText(poi, parameters: params, completion: {  (results:[AGSGeocodeResult]?, error:NSError?) -> Void in
                if let error = error {
                    print(error.localizedDescription)
                    self?.canDoExtentSearch = true
                }
                else {
                    self?.handleGeocodeResultsForPOIs(results, areExtentBased: (extent != nil))
                }
            })
        }
    }
    
    func handleGeocodeResultsForPOIs(geocodeResults:[AGSGeocodeResult]?, areExtentBased:Bool) {
        if let results = geocodeResults where results.count > 0 {
            
            //show the graphics on the map
            for result in results {
                let graphic = self.graphicForPoint(result.displayLocation!, attributes: result.attributes)
                
                self.graphicsOverlay.graphics.addObject(graphic)
            }
            
            //extent search button display logic
            //if search was not based on extent, then zoom to the graphics. On completion
            //set the canDoExtentSearch flag to true
            //else if search is based on extent, no need to zoom, simply set the flag to true
            if !areExtentBased {
                self.zoomToGraphics(self.graphicsOverlay.graphics as AnyObject as! [AGSGraphic])
            }
            else {
                self.canDoExtentSearch = true
            }
        }
        else {
            //show alert for no results
            print("No results found")
            //set canDoExtentSearch flag to true, so that if the user pans, the button becomes visible
            self.canDoExtentSearch = true
        }
    }
    
    //MARK: - Actions
    
    private func search() {
        //validation
        guard let poi = self.poiTextField.text where !poi.isEmpty else {
            print("Point of interest required")
            return
        }
        
        //cancel previous requests
        if self.suggestRequestOperation != nil {
            self.suggestRequestOperation.cancel()
        }
        
        //hide the table view
        self.animateTableView(false)
        
        //check if a suggestion is present
        if self.selectedSuggestResult != nil {
            //since a suggestion is selected, check if it was already geocoded to a location
            //if no, then goecode the suggestion
            //else use the geocoded location, to find the POIs
            if self.preferredSearchLocation == nil {
                self.geocodeUsingSuggestResult(self.selectedSuggestResult, completion: { [weak self] () -> Void in
                    //find the POIs wrt location
                    self?.geocodePOIs(poi, location: self!.preferredSearchLocation, extent: nil)
                    })
            }
            else {
                self.geocodePOIs(poi, location: self.preferredSearchLocation, extent: nil)
            }
        }
        else {
            if self.preferredSearchLocationTextField.text == self.currentLocationText {
                self.geocodePOIs(poi, location: self.mapView.locationDisplay.mapLocation, extent: nil)
            }
            else {
                self.geocodePOIs(poi, location: nil, extent: nil)
            }
        }
    }
    
    @IBAction private func searchInArea() {
        self.clearPreferredLocationInfo()
        self.geocodePOIs(self.poiTextField.text!, location: nil, extent: self.mapView.visibleArea!.extent)
    }
    
    //MARK: - Gesture recognizers
    
    @IBAction private func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    func showOverlayView() {
        self.overlayView.hidden = false
    }
    
    func hideOverlayView() {
        self.overlayView.hidden = true
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}


