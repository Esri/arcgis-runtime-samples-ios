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
    /// The map displayed in the map view.
    let map = AGSMap(basemap: .imageryWithLabels())

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var bannerLabel: UILabel!
    
    private var mapLoadStatusObservation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //setup source code bar button item
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["MapLoadedViewController"]
        
        //assign map to map view
        mapView.map = map
        
        mapLoadStatusObservation = map.observe(\.loadStatus, options: .initial) { [weak self] (_, _) in
            //update the banner label on main thread
            DispatchQueue.main.async { [weak self] in
                self?.updateLoadStatusLabel()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateLoadStatusLabel()
    }
    
    private func updateLoadStatusLabel() {
        bannerLabel.text = "Load status: \(map.loadStatus.title)"
    }
}

private extension AGSLoadStatus {
    /// The human readable name of the load status.
    var title: String {
        switch self {
        case .loaded:
            return "Loaded"
        case .loading:
            return "Loading"
        case .failedToLoad:
            return "Failed to Load"
        case .notLoaded:
            return "Not Loaded"
        case .unknown:
            fallthrough
        @unknown default:
            return "Unknown"
        }
    }
}
