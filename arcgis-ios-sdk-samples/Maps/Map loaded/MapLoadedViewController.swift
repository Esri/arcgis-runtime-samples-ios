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
    
    private var map:AGSMap?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //setup source code bar button item
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["MapLoadedViewController"]
        
        //initialize map with basemap
        self.map = AGSMap(basemap: AGSBasemap.imageryWithLabels())
        
        //assign map to map view
        self.mapView.map = self.map
        
        //register as an observer for loadStatus property on map
        self.map?.addObserver(self, forKeyPath: "loadStatus", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        //update the banner label on main thread
        DispatchQueue.main.async { [weak self] in
            
            //get the string for load status
            if let strongSelf = self, let loadStatus = strongSelf.map?.loadStatus {
                
                let loadStatusString = strongSelf.loadStatusString(loadStatus)
                
                //set it on the banner label
                strongSelf.bannerLabel.text = "Load status : \(loadStatusString)"
            }
        }
    }
    
    private func loadStatusString(_ status: AGSLoadStatus) -> String {
        switch status {
        case .failedToLoad:
            return "Failed_To_Load"
        case .loaded:
            return "Loaded"
        case .loading:
            return "Loading"
        case .notLoaded:
            return "Not_Loaded"
        default:
            return "Unknown"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        self.map?.removeObserver(self, forKeyPath: "loadStatus")
    }
}
