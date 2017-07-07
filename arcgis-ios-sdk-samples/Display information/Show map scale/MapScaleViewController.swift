// Copyright 2017 Esri.
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

class MapScaleViewController: UIViewController, MapScaleListVCDelegate, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var scaleView: UIView!
    @IBOutlet private weak var scaleLabel: UILabel!
    
    var pinch : UIPinchGestureRecognizer!
    
    let scales = ["1/1000", "1/5000", "1/25000", "1/50000", "1/100000", "1/1000000", "1/5000000"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["MapScaleViewController"]
        
        //initialize map with a basemap
        let map = AGSMap(basemap: AGSBasemap.streets())
        
        //assign the map to the map view
        self.mapView.map = map
        
        //assign the pinch gesture to the map view
        pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.mapPinchedByTouch(_:)))
        self.mapView.addGestureRecognizer(pinch)
        
        //set first extent to the map view
        self.mapView.setViewpointCenter(AGSPoint(x: -117.1618385, y: 32.7065281 , spatialReference: AGSSpatialReference.wgs84()), scale: 25000, completion: nil)
        
    }
    
    //User pinched on the map
    func mapPinchedByTouch(_ sender: UIPinchGestureRecognizer){
        
        self.showMapScale()
    }
    
    // Shows the map scale
    func showMapScale(){
        
        // scaleView.alpha default value set 0 in storyboard or viewDidLoad
        scaleView.alpha = 1
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formatted: String? = formatter.string(from: NSNumber(value: Int(self.mapView.mapScale)))
        scaleLabel.text = "1 / \(formatted ?? "")"
        
        //UIView Animation
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.8)
        UIView.setAnimationDelay(1.7)
        UIView.setAnimationCurve(.easeInOut)
        scaleView.alpha = 0
        UIView.commitAnimations()
        
    }
    
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MapScaleListSegue" {
            let controller = segue.destination as! MapScaleListViewController
            controller.delegate = self
            controller.scales = self.scales
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 200, height: 200)
        }
    }
    
    //MARK: - OperationsListVCDelegate
    
    func mapScaleListViewController(_ mapScaleListViewController: MapScaleListViewController, didSelectOperation index: Int) {
        
        switch index {
            
        case 0: // 1/1000
            self.mapView.setViewpointCenter(self.mapView.screen(toLocation: mapView.center), scale: 1000 , completion: {(success) -> Void in
                if success {
                    self.showMapScale();
                }
            })
        case 1: // 1/5000
            self.mapView.setViewpointCenter(self.mapView.screen(toLocation: mapView.center), scale: 5000 , completion: {(success) -> Void in
                if success {
                    self.showMapScale();
                }
            })
            
        case 2: // 1/25000
            self.mapView.setViewpointCenter(self.mapView.screen(toLocation: mapView.center), scale: 25000 , completion: {(success) -> Void in
                if success {
                    self.showMapScale();
                }
            })
            
        case 3: // 1/50000
            self.mapView.setViewpointCenter(self.mapView.screen(toLocation: mapView.center), scale: 50000 , completion: {(success) -> Void in
                if success {
                    self.showMapScale();
                }
            })
            
        case 4: // 1/100000
            self.mapView.setViewpointCenter(self.mapView.screen(toLocation: mapView.center), scale: 100000 , completion: {(success) -> Void in
                if success {
                    self.showMapScale();
                }
            })
            
        case 5: // 1/1000000
            self.mapView.setViewpointCenter(self.mapView.screen(toLocation: mapView.center), scale: 1000000 , completion: {(success) -> Void in
                if success {
                    self.showMapScale();
                }
            })
            
        case 6: // 1/5000000
            self.mapView.setViewpointCenter(self.mapView.screen(toLocation: mapView.center), scale: 5000000 , completion: {(success) -> Void in
                if success {
                    self.showMapScale();
                }
            })
            
        default: break
        }
        
    }
    
    
    //MARK: - UIAdaptivePresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        
        return UIModalPresentationStyle.none
    }
    
}
