//
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
//
import UIKit
import ArcGIS

class VectorTileCustomStyleVC: UIViewController, VectorStylesVCDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var visualEffectView: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["VectorTileCustomStyleVC", "VectorStylesViewController"]
        
        //default vector tiled layer
        let vectorTiledLayer = AGSArcGISVectorTiledLayer(URL: NSURL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=1349bfa0ed08485d8a92c442a3850b06")!)
        
        //initialize map with vector tiled layer as the basemap
        let map = AGSMap(basemap: AGSBasemap(baseLayer: vectorTiledLayer))
        
        //initial viewpoint
        let centerPoint = AGSPoint(x: 1990591.559979, y: 794036.007991, spatialReference: AGSSpatialReference(WKID: 3857))
        map.initialViewpoint = AGSViewpoint(center: centerPoint, scale: 88659253.829259947)
        
        //assign map to map view
        self.mapView.map = map
        
        //Add tap gesture on visual effect view to cancel
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideVisualEffectView))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        tapGestureRecognizer.delegate = self
        self.visualEffectView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func showSelectedItem(itemID: String) {
        let vectorTiledLayer = AGSArcGISVectorTiledLayer(URL: NSURL(string: "https://arcgisruntime.maps.arcgis.com/home/item.html?id=\(itemID)")!)
        self.mapView.map?.basemap = AGSBasemap(baseLayer: vectorTiledLayer)
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbedSegue" {
            let controller = segue.destinationViewController as! VectorStylesViewController
            controller.delegate = self
        }
    }
    
    //MARK: - VectorStylesVCDelegate
    
    func vectorStylesViewController(vectorStylesViewController: VectorStylesViewController, didSelectItemWithID itemID: String) {
        //show newly selected vector layer
        self.showSelectedItem(itemID)
        
        //hide visual effect view
        self.visualEffectView.hidden = true
    }
    
    //MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        //should receive touch only if tapped outside container view
        if let view = touch.view where view.isDescendantOfView(self.visualEffectView.contentView.subviews[0]) {
            return false
        }
        return true
    }
    
    //MARK: - Actions
    
    @IBAction func changeStyleAction() {
        self.visualEffectView.hidden = false
    }
    
    func hideVisualEffectView() {
        self.visualEffectView.hidden = true
    }
}
