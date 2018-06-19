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

class CalloutViewController: UIViewController, AGSGeoViewTouchDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    
    private var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["CalloutViewController"]
        
        //initialize map with topographic basemap
        self.map = AGSMap(basemap: AGSBasemap.topographic())
        //assign map to the map view
        self.mapView.map = self.map
        //register as the map view's touch delegate
        //in order to get tap notifications
        self.mapView.touchDelegate = self
        //zoom to custom view point
        self.mapView.setViewpointCenter(AGSPoint(x: -1.2e7, y: 5e6, spatialReference: AGSSpatialReference.webMercator()), scale: 4e7, completion: nil)
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    //user tapped on the map
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //if the callout is not shown, show the callout with the coordinates of the tapped location
        if self.mapView.callout.isHidden {
            self.mapView.callout.title = "Location"
            self.mapView.callout.detail = String(format: "x: %.2f, y: %.2f", mapPoint.x, mapPoint.y)
            self.mapView.callout.isAccessoryButtonHidden = true
            self.mapView.callout.show(at: mapPoint, screenOffset: CGPoint.zero, rotateOffsetWithMap: false, animated: true)
        }
        else {  //hide the callout
            self.mapView.callout.dismiss()
        }
    }
    
}
