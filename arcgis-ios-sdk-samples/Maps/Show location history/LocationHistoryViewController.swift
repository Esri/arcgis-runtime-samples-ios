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
    static let locationBorderColor = UIColor.backgroundGray
    static let locationInnerColor = UIColor.primaryTextColor
    static let trackColor = UIColor.primaryBlue.withAlphaComponent(0.5)

    static let locationDiameter: CGFloat = 14
    static let locationBorderWidth: CGFloat = 2
    static let trackWidth: CGFloat = 10

    static let initialZoomScale: Double = 10000
}

// MARK: - LocationTrackingStatus

private enum LocationTrackingStatus {
    case paused
    case inProgress
}

// MARK: - LocationHistoryViewController

class LocationHistoryViewController: UIViewController {
    @IBOutlet private weak var mapView: AGSMapView!
    @IBOutlet private weak var trackingBarButtonItem: UIBarButtonItem!
    
    private var currentStatus: LocationTrackingStatus = .paused {
        didSet {
            handleLocationStatusChange()
        }
    }
    
    private let locationsOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()

        let locationSymbol = AGSSimpleMarkerSymbol(style: .circle, color: Constants.locationInnerColor, size: Constants.locationDiameter)
        locationSymbol.outline = AGSSimpleLineSymbol(style: .solid, color: Constants.locationBorderColor, width: Constants.locationBorderWidth)

        overlay.renderer = AGSSimpleRenderer(symbol: locationSymbol)

        return overlay
    }()
    
    private let trackOverlay: AGSGraphicsOverlay = {
        let overlay = AGSGraphicsOverlay()

        let trackSymbol = AGSSimpleLineSymbol(style: .solid, color: Constants.trackColor, width: Constants.trackWidth)
        overlay.renderer = AGSSimpleRenderer(symbol: trackSymbol)

        return overlay
    }()

    private var trackBuilder: AGSPolylineBuilder?
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }
    
    // MARK: IBActions
    
    @IBAction private func trackingTapped(_ sender: UIBarButtonItem) {
        toggleTrackingStatus()
    }
    
    // MARK: Private behavior
    
    private func handleLocationStatusChange() {
        switch currentStatus {
        case .paused:
            stopProcessingLocationChanges()
        case .inProgress:
            startProcessingLocationChanges()
        }
        
        updateView(status: currentStatus)
    }
    
    private func processLocationUpdate() {
        guard currentStatus == .inProgress, let position = mapView.locationDisplay.mapLocation, position.x != 0, position.y != 0 else { return }
        
        let locationGraphic = AGSGraphic(geometry: position, symbol: nil)
        locationsOverlay.graphics.add(locationGraphic)

        guard let trackBuilder = trackBuilder else { return }

        trackBuilder.add(position)
        let trackGraphic = AGSGraphic(geometry: trackBuilder.toGeometry(), symbol: nil)
        trackOverlay.graphics.add(trackGraphic)
    }
    
    private func setupLocationDisplay(_ locationDisplay: AGSLocationDisplay) {
        locationDisplay.autoPanMode = .recenter
        locationDisplay.initialZoomScale = Constants.initialZoomScale
        
        locationDisplay.start { (error) in
            if let error = error {
                print("Error starting location display: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupMapView() {
        let map = AGSMap(basemap: .lightGrayCanvasVector())
        mapView.map = map

        map.load(completion: { [weak self, unowned map] (error) in
            self?.trackBuilder = AGSPolylineBuilder(spatialReference: map.spatialReference)
        })

        mapView.graphicsOverlays.addObjects(from: [trackOverlay, locationsOverlay])

        setupLocationDisplay(mapView.locationDisplay)

        updateView(status: currentStatus)
    }
    
    private func setupNavigationBar() {
        guard let sourceBarButtonItem = navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem else {
            return
        }

        sourceBarButtonItem.filenames = ["LocationHistoryViewController"]
    }
    
    private func setupView() {
        setupNavigationBar()

        setupMapView()
    }
    
    private func startProcessingLocationChanges() {
        mapView.locationDisplay.locationChangedHandler = { [weak self] (location) in
            guard location.horizontalAccuracy >= 0 else { return }

            DispatchQueue.main.async {
                self?.processLocationUpdate()
            }
        }
    }
    
    private func stopProcessingLocationChanges() {
        mapView.locationDisplay.locationChangedHandler = nil
    }
    
    private func toggleTrackingStatus() {
        switch currentStatus {
        case .paused:
            currentStatus = .inProgress
        case .inProgress:
            currentStatus = .paused
        }
    }
    
    private func updateView(status: LocationTrackingStatus) {
        let buttonText: String

        switch currentStatus {
        case .paused:
            buttonText = "Start tracking"
        case .inProgress:
            buttonText = "Stop tracking"
        }

        trackingBarButtonItem.title = buttonText
    }
}
