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

class MapLoadedViewController: UIViewController {

    @IBOutlet var mapView:AGSMapView!
    @IBOutlet var bannerLabel:UILabel!
    
    private var map:AGSMap!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //setup source code bar button item
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["MapLoadedViewController"]
        
        //initialize map with basemap
        self.map = AGSMap(basemap: AGSBasemap.imageryWithLabelsBasemap())
        
        //assign map to map view
        self.mapView.map = self.map
        
        //register as an observer for loadStatus property on map
        self.map.addObserver(self, forKeyPath: "loadStatus", options: .New, context: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        //update the banner label on main thread
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            
            if let weakSelf = self {
                //get the string for load status
                let loadStatusString = weakSelf.loadStatusString(weakSelf.map.loadStatus)
                
                //set it on the banner label
                weakSelf.bannerLabel.text = "Load status : \(loadStatusString)"
            }
        }
    }
    
    private func loadStatusString(status: AGSLoadStatus) -> String {
        switch status {
        case .FailedToLoad:
            return "Failed_To_Load"
        case .Loaded:
            return "Loaded"
        case .Loading:
            return "Loading"
        case .NotLoaded:
            return "Not_Loaded"
        default:
            return "Unknown"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
