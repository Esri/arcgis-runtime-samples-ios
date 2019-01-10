//
// Copyright 2018 Esri.
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

class SyncMapAndSceneViewsViewController: UIViewController {
    /// The map view to display the map.
    @IBOutlet private weak var mapView: AGSMapView!
    /// The scene view to display the scene.
    @IBOutlet private weak var sceneView: AGSSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SyncMapAndSceneViewsViewController"]
        
        // add a map with labeled imagery to the map view
        mapView.map = AGSMap(basemap: .imageryWithLabels())
        // add a scene with labeled imagery to the scene view
        sceneView.scene = AGSScene(basemap: .imageryWithLabels())
        
        // add handlers to each view to receive viewpoint change events
        mapView.viewpointChangedHandler = { [weak self] in
            guard let self = self else {
                return
            }
            self.synchronizeViewpoints(to: self.mapView)
        }
        sceneView.viewpointChangedHandler = { [weak self] in
            guard let self = self else {
                return
            }
            self.synchronizeViewpoints(to: self.sceneView)
        }
    }
    
    /// Sets the viewpoint of all views to that of the sender.
    private func synchronizeViewpoints(to sender: AGSGeoView) {
        // Check that the user is actively navigating this view, since viewpoint
        // change events are also called on `setViewpoint(_:)`. This check prevents
        // a feedback loop.
        guard sender.isNavigating,
            /// The viewpoint of the view currently being navigated.
            let senderViewpoint = sender.currentViewpoint(with: .centerAndScale) else {
            return
        }
        
        /// An array of views that we want to synchronize.
        let allGeoViews = [mapView, sceneView]
        
        // loop through all the views we want to sync and set their viewpoints
        for geoView in allGeoViews {
            // if this view isn't the sender
            if geoView != sender {
                // set the viewpoint to match that of the sender
                geoView?.setViewpoint(senderViewpoint)
            }
        }
    }
}
