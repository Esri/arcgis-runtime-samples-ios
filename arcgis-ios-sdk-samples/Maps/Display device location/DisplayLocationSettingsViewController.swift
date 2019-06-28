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

import UIKit
import ArcGIS

class DisplayLocationSettingsViewController: UITableViewController {
    // MARK: - Outlets
    
    @IBOutlet weak var showSwitch: UISwitch?
    @IBOutlet weak var autoPanModeCell: UITableViewCell?
    
    // MARK: - Model
    
    /// The SDK object for displaying the device location. Attached to the map view.
    weak var locationDisplay: AGSLocationDisplay? {
        didSet {
            updateUIForLocationDisplay()
        }
    }
    
    /// Returns a suitable interface label `String` for the mode.
    private func label(for autoPanMode: AGSLocationDisplayAutoPanMode) -> String {
        switch autoPanMode {
        case .off:
            return "Off"
        case .recenter:
            return "Re-Center"
        case .navigation:
            return "Navigation"
        case .compassNavigation:
            return "Compass Navigation"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func icon(for autoPanMode: AGSLocationDisplayAutoPanMode) -> UIImage? {
        switch autoPanMode {
        case .off:
            return #imageLiteral(resourceName: "LocationDisplayOffIcon")
        case .recenter:
            return #imageLiteral(resourceName: "LocationDisplayDefaultIcon")
        case .navigation:
            return #imageLiteral(resourceName: "LocationDisplayNavigationIcon")
        case .compassNavigation:
            return #imageLiteral(resourceName: "LocationDisplayHeadingIcon")
        @unknown default:
            return nil
        }
    }
    
    // MARK: - Views
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the UI for the initial model values
        updateUIForLocationDisplay()
        
        // The auto-pan mode may be updated by the SDK as well as the user,
        // so use the change handler to set the UI
        locationDisplay?.autoPanModeChangedHandler = { [weak self] (change) in
            // update the UI for the new mode
            self?.updateUIForAutoPanMode()
        }
    }
    
    private func updateUIForLocationDisplay() {
        showSwitch?.isOn = locationDisplay?.started == true
        updateUIForAutoPanMode()
    }
    
    private func updateUIForAutoPanMode() {
        if let autoPanMode = locationDisplay?.autoPanMode {
            autoPanModeCell?.detailTextLabel?.text = label(for: autoPanMode)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func showLocationSwitchAction(_ sender: UISwitch) {
        guard let locationDisplay = locationDisplay,
            // don't restart showing the location if it's already started
            locationDisplay.started != sender.isOn else {
                return
        }
        
        if sender.isOn {
            // To be able to request user permissions to get the device location,
            // make sure to add the location request field in the info.plist file
            
            // attempt to start showing the device location
            locationDisplay.start { [weak self] (error: Error?) in
                if let error = error {
                    // show the error if one occurred
                    self?.presentAlert(error: error)
                }
            }
        } else {
            // stop showing the device location
            locationDisplay.stop()
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        
        /// The modes in the order we want to display them in the interface.
        let orderedAutoPanModes = [AGSLocationDisplayAutoPanMode.off, .recenter, .navigation, .compassNavigation]
        
        if cell == autoPanModeCell,
            let autoPanMode = locationDisplay?.autoPanMode,
            let selectedIndex = orderedAutoPanModes.firstIndex(of: autoPanMode) {
            let options = orderedAutoPanModes.map { OptionsTableViewController.Option(label: label(for: $0), image: icon(for: $0)) }

            let controller = OptionsTableViewController(options: options, selectedIndex: selectedIndex) { (index) in
                // get the mode for the index
                let autoPanMode = orderedAutoPanModes[index]
                // set the displayed location mode to the selected one
                self.locationDisplay?.autoPanMode = autoPanMode
            }
            controller.title = cell.textLabel?.text
            show(controller, sender: self)
        }
    }
}
