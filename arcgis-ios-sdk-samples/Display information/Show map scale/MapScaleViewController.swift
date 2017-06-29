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

class MapScaleViewController: UIViewController {

    @IBOutlet private weak var mapView:AGSMapView!
    @IBOutlet private weak var scaleView: UIView!
    @IBOutlet private weak var scaleLabel: UILabel!
    
    var pinch : UIPinchGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["MapScaleViewController"]
        
        //initialize map with a basemap
        let map = AGSMap(basemap: AGSBasemap.topographic())
        
        //assign the map to the map view
        self.mapView.map = map
        
        //assign the pinch gesture to the map view
        pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.mapPinchedByTouch(_:)))
        self.mapView.addGestureRecognizer(pinch)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //User pinched on the map
    func mapPinchedByTouch(_ sender: UIPinchGestureRecognizer){
        
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
}
