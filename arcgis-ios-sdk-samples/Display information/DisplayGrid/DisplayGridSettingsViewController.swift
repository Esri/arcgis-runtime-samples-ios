//
// Copyright 2017 Esri.
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

class DisplayGridSettingsViewController: UIViewController, HorizontalPickerDelegate, HorizontalColorPickerDelegate {
    
    // MARK: - Variables
    
    var mapView: AGSMapView!
    var gridTypes = ["LatLong", "MGRS", "UTM", "USNG"]
    var labelPositions = ["Geographic", "Bottom Left", "Bottom Right", "Top Left", "Top Right", "Center", "All Sides"]
    var labelUnits = ["Kilometers Meters", "Meters"]
    var labelFormats = ["Decimal Degrees", "Degrees Minutes Seconds"]
    
    @IBOutlet var settingsView: UIView!
    @IBOutlet var gridTypePicker: HorizontalPicker!
    @IBOutlet var gridColorPicker: HorizontalColorPicker!
    @IBOutlet var gridVisibilitySwitch: UISwitch!
    @IBOutlet var labelVisibilitySwitch: UISwitch!
    @IBOutlet var labelColorPicker: HorizontalColorPicker!
    @IBOutlet var labelFormatPicker: HorizontalPicker!
    @IBOutlet var labelUnitPicker: HorizontalPicker!
    @IBOutlet var labelPositionPicker: HorizontalPicker!
    
    // MARK: - View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Corner radius for parent view
        self.settingsView.layer.cornerRadius = 10
        
        // Set picker options
        self.gridTypePicker.options = gridTypes
        self.labelPositionPicker.options = self.labelPositions
        self.labelUnitPicker.options = self.labelUnits
        self.labelFormatPicker.options = self.labelFormats
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        //
        // Setup UI Controls
        self.setupUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupUI() {
        //
        // Set current grid type
        if self.mapView.grid != nil {
            //
            // Set the grid type
            self.gridTypePicker.selectedIndex = self.gridTypes.index(of: self.currentGridType())!
            
            self.gridVisibilitySwitch.isOn = (self.mapView.grid?.isVisible)!
            self.labelVisibilitySwitch.isOn = (self.mapView.grid?.labelVisibility)!
            self.labelPositionPicker.selectedIndex = (self.mapView.grid?.labelPosition.rawValue)!
            
            if self.mapView.grid is AGSLatitudeLongitudeGrid {
                self.labelFormatPicker.isEnabled = true
                self.labelFormatPicker.selectedIndex = (self.mapView?.grid as! AGSLatitudeLongitudeGrid).labelFormat.rawValue
                self.labelUnitPicker.isEnabled = false
            }
            else if self.mapView.grid is AGSMGRSGrid {
                self.labelUnitPicker.isEnabled = true
                self.labelUnitPicker.selectedIndex = (self.mapView?.grid as! AGSMGRSGrid).labelUnit.rawValue
                self.labelFormatPicker.isEnabled = false
            }
            else if self.mapView.grid is AGSUTMGrid {
                self.labelUnitPicker.isEnabled = false
                self.labelFormatPicker.isEnabled = false
            }
            else if self.mapView.grid is AGSUSNGGrid {
                self.labelUnitPicker.isEnabled = true
                self.labelUnitPicker.selectedIndex = (self.mapView?.grid as! AGSUSNGGrid).labelUnit.rawValue
                self.labelFormatPicker.isEnabled = false
            }
        }
        
        // Set picker delegates
        self.gridTypePicker.delegate = self
        self.labelPositionPicker.delegate = self
        self.labelUnitPicker.delegate = self
        self.labelFormatPicker.delegate = self
        self.gridColorPicker.delegate = self
        self.labelColorPicker.delegate = self
    }
    
    //MARK: - Actions
    
    @IBAction private func closeAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func gridVisibilityAction() {
        self.mapView?.grid?.isVisible = self.gridVisibilitySwitch.isOn
    }
    
    @IBAction private func labelVisibilityAction() {
        self.mapView?.grid?.labelVisibility = self.labelVisibilitySwitch.isOn
    }
    
    // MARK: - Helper Functions

    private func currentGridType() -> String {
        if self.mapView.grid is AGSLatitudeLongitudeGrid {
            return "LatLong"
        }
        else if self.mapView.grid is AGSMGRSGrid {
            return "MGRS"
        }
        else if self.mapView.grid is AGSUTMGrid {
            return "UTM"
        }
        else if self.mapView.grid is AGSUSNGGrid {
            return "USNG"
        }
        else {
            return "LatLong"
        }
    }
    
    private func changeGrid() {
        //
        //
        var grid = AGSGrid()
        
        let gridType = self.gridTypePicker.options[self.gridTypePicker.selectedIndex]
        if (gridType == "LatLong") {
            grid = AGSLatitudeLongitudeGrid()
            self.labelFormatPicker.isEnabled = true
            self.labelUnitPicker.isEnabled = false
        }
        else if (gridType == "MGRS") {
            grid = AGSMGRSGrid()
            self.labelUnitPicker.isEnabled = true
            self.labelFormatPicker.isEnabled = false
        }
        else if (gridType == "UTM") {
            grid = AGSUTMGrid()
            self.labelUnitPicker.isEnabled = false
            self.labelFormatPicker.isEnabled = false
        }
        else if (gridType == "USNG") {
            grid = AGSUSNGGrid()
            self.labelUnitPicker.isEnabled = true
            self.labelFormatPicker.isEnabled = false
        }
        
        // Set selected grid
        self.mapView?.grid = grid
        
        // Apply settings to selected grid
        self.gridVisibilityAction()
        self.labelVisibilityAction()
        self.changeLabelPosition()
        self.changeLabelFormat()
        self.changeLabelUnit()
        
        if let selectedColor = self.gridColorPicker.selectedColor {
            self.changeGrid(color: selectedColor)
        }
        
        if let selectedColor = self.labelColorPicker.selectedColor {
            self.changeLabel(color: selectedColor)
        }
    }
    
    // Change the grid color
    private func changeGrid(color: UIColor) {
        if (self.mapView?.grid != nil) {
            let gridLevels = self.mapView?.grid?.levelCount
            for gridLevel in 0..<gridLevels! {
                let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: color, width: CGFloat(gridLevel+2))
                self.mapView?.grid?.setLineSymbol(lineSymbol, forLevel: gridLevel)
            }
        }
    }
    
    // Change the grid label color
    private func changeLabel(color: UIColor) {
        if (self.mapView?.grid != nil) {
            let gridLevels = self.mapView?.grid?.levelCount
            for gridLevel in 0..<gridLevels! {
                let textSymbol = AGSTextSymbol()
                textSymbol.color = color
                textSymbol.size = 14
                textSymbol.horizontalAlignment = .left
                textSymbol.verticalAlignment = .bottom
                textSymbol.haloColor = UIColor.white
                textSymbol.haloWidth = CGFloat(gridLevel+2)
                self.mapView?.grid?.setTextSymbol(textSymbol, forLevel: gridLevel)
            }
        }
    }
    
    // Change the grid label position
    private func changeLabelPosition() {
        self.mapView.grid?.labelPosition = AGSGridLabelPosition(rawValue: self.labelPositionPicker.selectedIndex)!
    }
    
    // Change the grid label format
    private func changeLabelFormat() {
        if self.mapView.grid is AGSLatitudeLongitudeGrid {
            (self.mapView?.grid as! AGSLatitudeLongitudeGrid).labelFormat = AGSLatitudeLongitudeGridLabelFormat(rawValue: self.labelFormatPicker.selectedIndex)!
        }
    }
    
    // Change the grid label unit
    private func changeLabelUnit() {
        if self.mapView.grid is AGSMGRSGrid {
            (self.mapView?.grid as! AGSMGRSGrid).labelUnit = AGSMGRSGridLabelUnit(rawValue: self.labelUnitPicker.selectedIndex)!
        }
        else if self.mapView.grid is AGSUSNGGrid {
            (self.mapView?.grid as! AGSUSNGGrid).labelUnit = AGSUSNGGridLabelUnit(rawValue: self.labelUnitPicker.selectedIndex)!
        }
    }
    
    // MARK: Horizontal Picker Delegate
    
    internal func horizontalPicker(_ horizontalPicker: HorizontalPicker, didUpdateSelectedIndex index: Int) {
        if horizontalPicker == self.gridTypePicker {
            self.changeGrid()
        }
        else if horizontalPicker == self.labelPositionPicker {
            self.changeLabelPosition()
        }
        else if horizontalPicker == self.labelFormatPicker {
            self.changeLabelFormat()
        }
        else if horizontalPicker == self.labelUnitPicker {
            self.changeLabelUnit()
        }
    }
    
    // MARK: Horizontal Color Picker Delegate

    func horizontalColorPicker(_ horizontalColorPicker: HorizontalColorPicker, didUpdateSelectedColor selectedColor: UIColor) {
        if horizontalColorPicker == self.gridColorPicker {
            self.changeGrid(color: selectedColor)
        }
        else if horizontalColorPicker == self.labelColorPicker {
            self.changeLabel(color: selectedColor)
        }
    }
}
