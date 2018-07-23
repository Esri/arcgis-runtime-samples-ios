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
    case poi
    case populatedPlace
}

class FindPlaceViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, AGSGeoViewTouchDelegate {
    
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
    private var suggestRequestOperation:AGSCancelable!
    private var selectedSuggestResult:AGSSuggestResult!
    private var preferredSearchLocation:AGSPoint!
    private var selectedTextField:UITextField!
    
    private var isTableViewVisible = true
    private var isTableViewAnimating = false
    private var canDoExtentSearch = false {
        didSet {
            if !canDoExtentSearch {
                self.extentSearchButton.isHidden = true
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
        self.map = AGSMap(basemap: AGSBasemap.topographic())
        
        //assign the map to the map view
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
        //start location display
        self.mapView.locationDisplay.autoPanMode = .recenter
        self.mapView.locationDisplay.start { [weak self] (error: Error?) -> Void in
            if error == nil {
                //if the location display starts, update the preferred search location
                //textfield's text
                self?.preferredSearchLocationTextField.text = self!.currentLocationText
            }
        }
        
        //logic to show the extent search button
        self.mapView.viewpointChangedHandler = { [weak self] () -> Void in
            DispatchQueue.main.async {
                if self?.canDoExtentSearch ?? false {
                    self?.extentSearchButton.isHidden = false
                }
            }
        }
        
        //instantiate the graphicsOverlay and add to the map view
        self.graphicsOverlay = AGSGraphicsOverlay()
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        //initialize locator task
        self.locatorTask = AGSLocatorTask(url: URL(string: "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer")!)
        
        //hide suggest result table view by default
        self.animateTableView(expand: false)
        
        //hide the overlay view by default
        self.overlayView.isHidden = true
        
        //register for keyboard notification in order to toggle overlay view on and off
        NotificationCenter.default.addObserver(self, selector: #selector(FindPlaceViewController.showOverlayView), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FindPlaceViewController.hideOverlayView), name: .UIKeyboardWillHide, object: nil)
        
        //add the left view images for both the textfields
        self.setupTextFieldLeftViews()
    }
    
    //method to show search icon and pin icon for the textfields
    private func setupTextFieldLeftViews() {
        var leftView = self.textFieldViewWithImage("SearchIcon")
        self.poiTextField.leftView = leftView
        self.poiTextField.leftViewMode = UITextFieldViewMode.always
        
        leftView = self.textFieldViewWithImage("PinIcon")
        self.preferredSearchLocationTextField.leftView = leftView
        self.preferredSearchLocationTextField.leftViewMode = UITextFieldViewMode.always
    }
    
    //method returns a UIView with an imageView as the subview
    //with an image instantiated using the name provided
    private func textFieldViewWithImage(_ imageName:String) -> UIView {
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
            UIView.animate(withDuration: 0.1, animations: { [weak self] () -> Void in
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
        self.animateTableView(expand: false)
        self.selectedSuggestResult = nil
        self.preferredSearchLocation = nil
    }
    
    //method to show callout for a graphic
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
    
    //method returns a graphic object for the specified point and attributes
    private func graphicForPoint(_ point: AGSPoint, attributes:[String:AnyObject]?) -> AGSGraphic {
        let markerImage = UIImage(named: "RedMarker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height/2
        symbol.offsetY = markerImage.size.height/2
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: attributes)
        return graphic
    }
    
    //method to zoom to an array of graphics
    func zoomToGraphics(_ graphics:[AGSGraphic]) {
        if graphics.count > 0 {
            let multipoint = AGSMultipointBuilder(spatialReference: graphics[0].geometry!.spatialReference)
            for graphic in graphics {
                multipoint.points.add(graphic.geometry as! AGSPoint)
            }
            self.mapView.setViewpoint(AGSViewpoint(targetExtent: multipoint.extent)) { [weak self] (finished:Bool) -> Void in
                self?.canDoExtentSearch = true
            }
        }
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //dismiss the callout if already visible
        self.mapView.callout.dismiss()
        
        //identify graphics at the tapped location
        self.mapView.identify(self.graphicsOverlay, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 1) { (result: AGSIdentifyGraphicsOverlayResult) -> Void in
            if let error = result.error {
                print(error)
            }
            else if result.graphics.count > 0 {
                //show callout for the first graphic in the array
                self.showCalloutForGraphic(result.graphics[0], tapLocation: mapPoint)
            }
        }
    }
    
    //MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rows = 0
        if let count = self.suggestResults?.count {
            if self.selectedTextField == self.preferredSearchLocationTextField {
                rows = count + 1
            }
            else {
                rows = count
            }
        }
        self.animateTableView(expand: rows > 0)
        return rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestCell", for: indexPath)
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
        self.animateTableView(expand: false)
    }
    
    //MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let newString = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if textField == self.preferredSearchLocationTextField {
            self.selectedTextField = self.preferredSearchLocationTextField
            if !newString.isEmpty {
                self.fetchSuggestions(newString, suggestionType: .populatedPlace, textField: self.preferredSearchLocationTextField)
            }
            self.clearPreferredLocationInfo()
        }
        else {
            self.selectedTextField = self.poiTextField
            if !newString.isEmpty {
                self.fetchSuggestions(newString, suggestionType: .poi, textField:self.poiTextField)
            }
            else {
                self.canDoExtentSearch = false
                self.animateTableView(expand: false)
            }
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        if textField == self.preferredSearchLocationTextField {
            self.clearPreferredLocationInfo()
        }
        else {
            self.canDoExtentSearch = false
            self.animateTableView(expand: false)
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        self.search()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.animateTableView(expand: false)
    }
    
    //MARK: - Suggestions logic
    
    private func fetchSuggestions(_ string:String, suggestionType:SuggestionType, textField:UITextField) {
        //cancel previous requests
        if self.suggestRequestOperation != nil {
            self.suggestRequestOperation.cancel()
        }
        
        //initialize suggest parameters
        let suggestParameters = AGSSuggestParameters()
        let flag:Bool = (suggestionType == SuggestionType.poi)
        suggestParameters.categories = flag ? ["POI"] : ["Populated Place"]
        suggestParameters.preferredSearchLocation = flag ? nil : self.mapView.locationDisplay.mapLocation
        
        //get suggestions
        self.suggestRequestOperation = self.locatorTask.suggest(withSearchText: string, parameters: suggestParameters) { (result: [AGSSuggestResult]?, error: Error?) -> Void in
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
    
    private func geocodeUsingSuggestResult(_ suggestResult:AGSSuggestResult, completion: @escaping () -> Void) {
            
        //create geocode params
        let params = AGSGeocodeParameters()
        params.outputSpatialReference = self.mapView.spatialReference
        
        //geocode with selected suggest result
        self.locatorTask.geocode(with: suggestResult, parameters: params) { [weak self] (result: [AGSGeocodeResult]?, error: Error?) -> Void in
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                if let result = result , result.count > 0 {
                    self?.preferredSearchLocation = result[0].displayLocation
                    completion()
                }
                else {
                    print("No location found for the suggest result")
                }
            }
        }
    }
    
    private func geocodePOIs(_ poi:String, location:AGSPoint?, extent:AGSGeometry?) {
        //hide callout if already visible
        self.mapView.callout.dismiss()
        
        //hide extent search button
        self.canDoExtentSearch = false
        self.extentSearchButton.isHidden = true
        
        //remove all previous graphics
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //parameters for geocoding POIs
        let params = AGSGeocodeParameters()
        params.preferredSearchLocation = location
        params.searchArea = extent
        params.outputSpatialReference = self.mapView.spatialReference
        params.resultAttributeNames.append(contentsOf: ["*"])
        
            
        //geocode using the search text and params
        self.locatorTask.geocode(withSearchText: poi, parameters: params) { [weak self] (results:[AGSGeocodeResult]?, error:Error?) -> Void in
            if let error = error {
                print(error.localizedDescription)
                self?.canDoExtentSearch = true
            }
            else {
                self?.handleGeocodeResultsForPOIs(results, areExtentBased: (extent != nil))
            }
        }
    }
    
    func handleGeocodeResultsForPOIs(_ geocodeResults:[AGSGeocodeResult]?, areExtentBased:Bool) {
        if let results = geocodeResults , results.count > 0 {
            
            //show the graphics on the map
            for result in results {
                let graphic = self.graphicForPoint(result.displayLocation!, attributes: result.attributes as [String : AnyObject]?)
                
                self.graphicsOverlay.graphics.add(graphic)
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
        guard let poi = self.poiTextField.text , !poi.isEmpty else {
            print("Point of interest required")
            return
        }
        
        //cancel previous requests
        if self.suggestRequestOperation != nil {
            self.suggestRequestOperation.cancel()
        }
        
        //hide the table view
        self.animateTableView(expand: false)
        
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
    
    @objc func showOverlayView() {
        self.overlayView.isHidden = false
    }
    
    @objc func hideOverlayView() {
        self.overlayView.isHidden = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


