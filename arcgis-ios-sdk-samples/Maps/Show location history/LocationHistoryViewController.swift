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

// MARK: - Constants

private enum Constants {
    static let initialLatitude: Double = 34.056295
    static let initialLongitude: Double = -117.195800
    static let levelOfDetail: Int = 18
}

// MARK: - LocationHistoryViewController

class LocationHistoryViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var trackingBarButtonItem: UIBarButtonItem!
    
    private let map = AGSMap(basemapType: .lightGrayCanvasVector, latitude: Constants.initialLatitude, longitude: Constants.initialLongitude, levelOfDetail: Constants.levelOfDetail)
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.isToolbarHidden = false
    }
    
    // MARK: IBActions
    
    @IBAction private func trackingTapped(_ sender: UIBarButtonItem) {}
    
    // MARK: Private behavior
    
    private func setupMapView() {
        mapView.map = map
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
        setupMapView()
        
        setupToolbar()
    }
}
