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

class IdentifyLayersViewController: UIViewController, AGSGeoViewTouchDelegate, IdentifyResultsVCDelegate {
    
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var containerView:UIView!
    @IBOutlet var mapViewBottomConstraint:NSLayoutConstraint!
    @IBOutlet var mapViewZeroBottomConstraint:NSLayoutConstraint!
    
    private var map:AGSMap!
    
    private var featureLayer:AGSFeatureLayer!
    private var mapImageLayer:AGSArcGISMapImageLayer!
    
    private var selectedGeoElements:[AGSGeoElement]!
    
    private var identifyResultsVC:IdentifyResultsViewController!
    private var graphicsOverlay = AGSGraphicsOverlay()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["IdentifyLayersViewController", "IdentifyResultsViewController", "GeoElementCell"]
        
        //create an instance of a map
        self.map = AGSMap()
        
        self.mapImageLayer = AGSArcGISMapImageLayer(URL: NSURL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/SampleWorldCities/MapServer")!)
        
        self.map.operationalLayers.addObject(self.mapImageLayer)
        
        //feature table
        let featureTable = AGSServiceFeatureTable(URL: NSURL(string: "https://sampleserver6.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0")!)
        //feature layer
        self.featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        //add feature layer add to the operational layers
        self.map.operationalLayers.addObject(self.featureLayer)
        
        //set initial viewpoint to a specific region
        self.map.initialViewpoint = AGSViewpoint(center: AGSPoint(x: -10977012.785807, y: 4514257.550369, spatialReference: AGSSpatialReference(WKID: 3857)), scale: 68015210)
        
        //assign map to the map view
        self.mapView.map = self.map
        
        //add self as the touch delegate for the map view
        self.mapView.touchDelegate = self
        
        //add graphics overlay, used for highlighting identified elements
        self.mapView.graphicsOverlays.addObject(self.graphicsOverlay)
        
        //hide the results view controller initially
        self.toggleContainerView(false, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //get the geoElements for all layers present at the tapped point
        self.identifyLayers(screenPoint)
    }
    
    //MARK: - Identify layers
    
    private func identifyLayers(screen: CGPoint) {
        //show progress hud
        SVProgressHUD.showWithStatus("Identifying", maskType: .Gradient)
        
        self.mapView.identifyLayersAtScreenPoint(screen, tolerance: 22, maximumResultsPerLayer: 10) { (results: [AGSIdentifyLayerResult]?, error: NSError?) in
            
            //dismiss progress hud
            SVProgressHUD.dismiss()
            
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription, maskType: .Gradient)
            }
            else {
                //get all the geoElements from the results
                self.selectedGeoElements = self.geoElementsFromResults(results!)
                //keep a reference to the geoElements to be used later
                self.identifyResultsVC.geoElements = self.selectedGeoElements
                
                if self.selectedGeoElements.count > 0 {
                    
                    //select the first geo element on the map view
                    self.selectGeoElement(self.selectedGeoElements[0], completion: {
                        
                        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
                        dispatch_after(delayTime, dispatch_get_main_queue(), { [weak self] in
                            //show the container view populated with the geo elements
                            self?.toggleContainerView(true, animated: true)
                        })
                    })
                }
                else {
                    SVProgressHUD.showInfoWithStatus("No element found", maskType: .Gradient)
                    //hide the container view
                    self.toggleContainerView(false, animated: true)
                    //clear any graphics in the graphics overlay
                    self.graphicsOverlay.graphics.removeAllObjects()
                }
            }
        }
    }
    
    //MARK: - Helper methods
    
    private func selectGeoElement(geoElement:AGSGeoElement, completion: (Void -> Void)? ) {
        //clear graphics overlay to remove any previous highlighted geometry
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //create symbol based on the type of geometry
        var symbol:AGSSymbol
        if geoElement.geometry is AGSPoint {
            symbol = AGSSimpleMarkerSymbol(style: .Circle, color: UIColor.cyanColor().colorWithAlphaComponent(0.8), size: 15)
        }
        else if geoElement is AGSPolyline {
            symbol = AGSSimpleLineSymbol(style: .Dash, color: UIColor.cyanColor().colorWithAlphaComponent(0.8), width: 5)
        }
        else {
            symbol = AGSSimpleFillSymbol(style: .Cross, color: UIColor.cyanColor().colorWithAlphaComponent(0.8), outline: nil)
        }
        let graphic = AGSGraphic(geometry: geoElement.geometry!, symbol: symbol)
        
        //add graphic to the overlay
        graphicsOverlay.graphics.addObject(graphic)
        
        //zoom to the added graphic
        self.mapView.setViewpointGeometry(geoElement.geometry!.extent, padding: 50) { (finished) in
            completion?()
        }
    }
    
    private func geoElementsFromResults(results:[AGSIdentifyLayerResult]) -> [AGSGeoElement] {
        //create temp variable to allow additions to array
        var tempResults = results
        
        //using Depth First Search approach to handle recursion
        var geoElements = [AGSGeoElement]()
        var count = 0
        
        while count < tempResults.count {
            //get the result object from the array
            let identifyResult = tempResults[count]
            
            for element in identifyResult.geoElements {
                element.layerName = identifyResult.layerContent.name
            }
            
            //add the geoElements from the result
            geoElements.appendContentsOf(identifyResult.geoElements)
            
            //check if the result has any sublayer results
            //if yes then add those result objects in the tempResults
            //array after the current result
            if identifyResult.sublayerResults.count > 0 {
                tempResults.insertContentsOf(identifyResult.sublayerResults, at: count+1)
            }
            
            //update the count and repeat
            count += 1
        }
        
        return geoElements
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "IdentifyResultsEmbedSegue" {
            self.identifyResultsVC = segue.destinationViewController as! IdentifyResultsViewController
            self.identifyResultsVC.delegate = self
        }
    }
    
    //MARK: - Show/Hide container view
    
    private func toggleContainerView(on:Bool, animated:Bool) {
        self.mapViewBottomConstraint.active = on
        self.mapViewZeroBottomConstraint.active = !on
        
        if !animated {
            self.view.layoutIfNeeded()
        }
        else {
            UIView.animateWithDuration(0.3, animations: { [weak self] in
                self?.view.layoutIfNeeded()
            }) { (finished: Bool) in
                
            }
        }
    }
    
    //MARK: - IdentifyResultsVCDelegate
    
    func identifyResultsViewController(identifyResultsViewController: IdentifyResultsViewController, didSelectGeoElementAtIndex index: Int) {
        //select the geoElement on the map view
        self.selectGeoElement(self.selectedGeoElements[index], completion: nil)
    }
    
    func identifyResultsViewControllerWantsToClose(identifyResultsViewController: IdentifyResultsViewController) {
        //toggle the container view off
        self.toggleContainerView(false, animated: true)
        //clear any graphics in the graphics overlay
        self.graphicsOverlay.graphics.removeAllObjects()
    }
}



//MARK: - Extension
var layerNameHandle:UInt8 = 0

//extending AGSGeoElement to include a layerName property
//to be used in the collection view
extension AGSGeoElement {
    
    var layerName:String {
        get {
            return objc_getAssociatedObject(self, &layerNameHandle) as? String ?? ""
        }
        set {
            objc_setAssociatedObject(self, &layerNameHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}


