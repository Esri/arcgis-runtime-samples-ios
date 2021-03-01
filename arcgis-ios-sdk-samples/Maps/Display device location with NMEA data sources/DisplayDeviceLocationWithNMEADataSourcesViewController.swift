// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class DisplayDeviceLocationWithNMEADataSourcesViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISNavigation)
        }
    }
    /// The label to display satellites info.
    @IBOutlet var statusLabel: UILabel!
    /// The button to start the demo.
    @IBOutlet var startBarButtonItem: UIBarButtonItem!
    /// The button to reset pan mode to "recenter".
    @IBOutlet var recenterBarButtonItem: UIBarButtonItem!
    /// The button to reset the demo.
    @IBOutlet var resetBarButtonItem: UIBarButtonItem!
    
    // MARK: Instance properties
    
    /// An NMEA location data source, to parse NMEA data.
    let nmeaLocationDataSource = AGSNMEALocationDataSource(receiverSpatialReference: .wgs84())
    /// A mock data source to read NMEA sentences from a local file, and generate
    /// mock NMEA data every fixed amount of time.
    let mockNMEADataSource = SimulatedNMEADataSource(nmeaSourceFile: Bundle.main.url(forResource: "Redlands", withExtension: "nmea")!, speed: 1.5)
    
    // MARK: Actions
    
    @IBAction func start() {
        // Set buttons states.
        startBarButtonItem.isEnabled = false
        resetBarButtonItem.isEnabled = true
        // Set NMEA location data source for location display.
        mapView.locationDisplay.dataSource = nmeaLocationDataSource
        // Start the data source and location display.
        mockNMEADataSource.start()
        mapView.locationDisplay.start()
        // Recenter the map and set pan mode.
        recenter()
    }
    
    @IBAction func recenter() {
        mapView.locationDisplay.autoPanMode = .recenter
        recenterBarButtonItem.isEnabled = false
        mapView.locationDisplay.autoPanModeChangedHandler = { [weak self] _ in
            DispatchQueue.main.async {
                self?.recenterBarButtonItem.isEnabled = true
            }
            self?.mapView.locationDisplay.autoPanModeChangedHandler = nil
        }
    }
    
    @IBAction func reset() {
        // Reset buttons states.
        startBarButtonItem.isEnabled = true
        resetBarButtonItem.isEnabled = false
        // Reset the status text.
        statusLabel.text = "Satellites info will be shown here."
        // Reset and stop the location display.
        mapView.locationDisplay.autoPanModeChangedHandler = nil
        mapView.locationDisplay.autoPanMode = .off
        mapView.locationDisplay.stop()
        // Pause the mock data generation.
        mockNMEADataSource.stop()
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "DisplayDeviceLocationWithNMEADataSourcesViewController",
            "SimulatedNMEADataSource"
        ]
        // Load NMEA location data source.
        startBarButtonItem.isEnabled = true
        nmeaLocationDataSource.locationChangeHandlerDelegate = self
        mockNMEADataSource.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reset()
    }
}

// MARK: SimulatedNMEADataSourceDelegate

extension DisplayDeviceLocationWithNMEADataSourcesViewController: SimulatedNMEADataSourceDelegate {
    func dataSource(_ dataSource: SimulatedNMEADataSource, didUpdate nmeaData: Data) {
        // Push mock data into the data source.
        // Note: You can also get real-time NMEA sentences from a GPS dongle.
        nmeaLocationDataSource.push(nmeaData)
    }
}

// MARK: AGSNMEALocationDataSourceDelegate

extension DisplayDeviceLocationWithNMEADataSourcesViewController: AGSNMEALocationDataSourceDelegate {
    func nmeaLocationDataSource(_ NMEALocationDataSource: AGSNMEALocationDataSource, satellitesDidChange satellites: [AGSNMEASatelliteInfo]) {
        // Update the satellites info status text.
        let satelliteSystemsText = Set(satellites.map(\.system.label))
            .sorted()
            .joined(separator: ", ")
        let idText = satellites
            .map { String($0.satelliteID) }
            .joined(separator: ", ")
        let statusText =
            """
            \(satellites.count) satellites in view
            System(s): \(satelliteSystemsText)
            IDs: \(idText)
            """
        statusLabel.text = statusText
    }
}

private extension AGSNMEAGNSSSystem {
    var label: String {
        switch self {
        case .GPS:
            return "The Global Positioning System"
        case .GLONASS:
            return "The Russian Global Navigation Satellite System"
        case .galileo:
            return "The European Union Global Navigation Satellite System"
        case .BDS:
            return "The BeiDou Navigation Satellite System"
        case .QZSS:
            return "The Quasi-Zenith Satellite System"
        case .navIC:
            return "The Navigation Indian Constellation"
        default:
            return "Unknown GNSS type"
        }
    }
}
