//
// Copyright © 2019 Esri.
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

// MARK: - LocationHistoryViewController

class LocationHistoryViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var trackingBarButtonItem: UIBarButtonItem!
    
    private var locationTracker: LocationTracker?
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLocationTracking()
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setToolbarHidden(false, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    // MARK: IBActions
    
    @IBAction private func trackingTapped(_ sender: UIBarButtonItem) {
        locationTracker?.toggleTrackingStatus()
    }
    
    // MARK: Private behavior
    
    private func setupLocationTracking() {
        locationTracker = LocationTracker(mapView: mapView, historyView: self)
    }
    
    private func setupNavigationBar() {
        guard let sourceBarButtonItem = navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem else {
            return
        }
        
        sourceBarButtonItem.filenames = [
            "LocationHistoryViewController",
            "LocationTracking"
        ]
    }
    
    private func setupToolbar() {
        let leadingSpaceToolbarItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let trailingSpaceToolbarItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbarItems = [
            leadingSpaceToolbarItem,
            trackingBarButtonItem,
            trailingSpaceToolbarItem
        ]
    }
    
    private func setupView() {
        setupNavigationBar()
        
        setupToolbar()
    }
}

// MARK: - LocationHistoryView

extension LocationHistoryViewController: LocationHistoryView {
    func setTrackingButtonText(value: String) {
        trackingBarButtonItem.title = value
    }
}
