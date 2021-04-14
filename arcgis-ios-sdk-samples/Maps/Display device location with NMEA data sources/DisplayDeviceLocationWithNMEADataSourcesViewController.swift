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
    /// The button to choose a data source and start the demo.
    @IBOutlet var sourceBarButtonItem: UIBarButtonItem!
    /// The button to reset pan mode to "recenter".
    @IBOutlet var recenterBarButtonItem: UIBarButtonItem!
    /// The button to reset the demo.
    @IBOutlet var resetBarButtonItem: UIBarButtonItem!
    
    // MARK: Constants
    
    /// The protocols specified in the `Info.plist` that the app uses to
    /// communicate with external accessory hardware.
    let supportedProtocolStrings: [String] = {
        guard let protocols = Bundle.main.object(forInfoDictionaryKey: "UISupportedExternalAccessoryProtocols") as? [String] else {
            return []
        }
        return protocols
    }()
    
    // MARK: Instance properties
    
    /// An NMEA location data source, to parse NMEA data.
    var nmeaLocationDataSource: AGSNMEALocationDataSource?
    /// A string to hold the latest satellite info.
    var satelliteInfoText = "Satellites info will be shown here."
    /// A mock data source to read NMEA sentences from a local file, and generate
    /// mock NMEA data every fixed amount of time.
    let mockNMEADataSource = SimulatedNMEADataSource(nmeaSourceFile: Bundle.main.url(forResource: "Redlands", withExtension: "nmea")!, speed: 1.5)
    /// A formatter for the accuracy distance string.
    let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.minimumFractionDigits = 1
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()
    
    // MARK: Actions
    
    @IBAction func chooseDataSource(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Choose an NMEA data source.",
            message: nil,
            preferredStyle: .actionSheet
        )
        // Populate from connected GNSS surveyor devices.
        EAAccessoryManager.shared().connectedAccessories.forEach { accessory in
            // The protocol string to establish the EASession.
            guard let protocolString = accessory.protocolStrings.first(where: { supportedProtocolStrings.contains($0) }) else {
                // Skip any device which protocol is not included in the plist.
                // This typically shouldn't happen, unless the device requires
                // additional configuration.
                return
            }
            let action = UIAlertAction(title: accessory.name, style: .default) { [self] _ in
                nmeaLocationDataSource = AGSNMEALocationDataSource(eaAccessory: accessory, protocol: protocolString)
                nmeaLocationDataSource?.locationChangeHandlerDelegate = self
                start()
            }
            alertController.addAction(action)
        }
        // Add mock data source to the options.
        let mockDataSourceAction = UIAlertAction(title: "Mock Data", style: .default) { [self] _ in
            nmeaLocationDataSource = AGSNMEALocationDataSource(receiverSpatialReference: .wgs84())
            nmeaLocationDataSource!.locationChangeHandlerDelegate = self
            mockNMEADataSource.delegate = self
            start()
        }
        alertController.addAction(mockDataSourceAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = sender
        present(alertController, animated: true)
    }
    
    func start() {
        guard let dataSource = nmeaLocationDataSource else {
            presentAlert(title: "Error", message: "NMEA data source failed to initialize from GNSS surveyor!")
            return
        }
        // Set NMEA location data source for location display.
        mapView.locationDisplay.dataSource = dataSource
        // Set buttons states.
        sourceBarButtonItem.isEnabled = false
        resetBarButtonItem.isEnabled = true
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
        resetBarButtonItem.isEnabled = false
        sourceBarButtonItem.isEnabled = true
        // Reset the status text.
        statusLabel.text = "Location info will be shown here."
        satelliteInfoText = "Satellites info will be shown here."
        // Reset and stop the location display.
        mapView.locationDisplay.autoPanModeChangedHandler = nil
        mapView.locationDisplay.autoPanMode = .off
        mapView.locationDisplay.stop()
        // Pause the mock data generation.
        mockNMEADataSource.stop()
        // Disconnect from the mock data updates.
        mockNMEADataSource.delegate = nil
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "DisplayDeviceLocationWithNMEADataSourcesViewController",
            "SimulatedNMEADataSource"
        ]
        sourceBarButtonItem.isEnabled = true
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
        // Note: You can also get real-time NMEA sentences from a GNSS surveyor.
        nmeaLocationDataSource?.push(nmeaData)
    }
}

// MARK: AGSNMEALocationDataSourceDelegate

extension DisplayDeviceLocationWithNMEADataSourcesViewController: AGSNMEALocationDataSourceDelegate {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        guard let nmeaLocation = location as? AGSNMEALocation else { return }
        let horizontalAccuracy = Measurement(
            value: nmeaLocation.horizontalAccuracy,
            unit: UnitLength.meters
        )
        let verticalAccuracy = Measurement(
            value: nmeaLocation.verticalAccuracy,
            unit: UnitLength.meters
        )
        let accuracyText = String(
            format: "Accuracy - Horizontal: %@; Vertical: %@",
            distanceFormatter.string(from: horizontalAccuracy),
            distanceFormatter.string(from: verticalAccuracy)
        )
        statusLabel.text = accuracyText + "\n" + satelliteInfoText
    }
    
    func nmeaLocationDataSource(_ NMEALocationDataSource: AGSNMEALocationDataSource, satellitesDidChange satellites: [AGSNMEASatelliteInfo]) {
        // Update the satellites info status text.
        let satelliteSystemsText = Set(satellites.map(\.system.label))
            .sorted()
            .joined(separator: ", ")
        let idText = satellites
            .map { String($0.satelliteID) }
            .joined(separator: ", ")
        satelliteInfoText = String(
            format: "%d satellites in view\nSystem(s): %@\nIDs: %@",
            satellites.count,
            satelliteSystemsText,
            idText
        )
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
