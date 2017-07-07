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

enum GridType: Int {
    case LatLong = 0
    case MGRS = 1
    case UTM = 2
    case USNG = 3
}

class DisplayGridSettingsViewController: UIViewController, HorizontalPickerDelegate, HorizontalColorPickerDelegate {
    
    // MARK: - Variables
    
    var mapView: AGSMapView?
    var gridTypes = ["LatLong", "MGRS", "UTM", "USNG"]
    var labelPositions = ["Geographic", "Bottom Left", "Bottom Right", "Top Left", "Top Right", "Center", "All Sides"]
    var labelUnits = ["Kilometers Meters", "Meters"]
    var labelFormats = ["Decimal Degrees", "Degrees Minutes Seconds"]
    
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var gridTypePicker: HorizontalPicker!
    @IBOutlet weak var gridColorPicker: HorizontalColorPicker!
    @IBOutlet weak var gridVisibilitySwitch: UISwitch!
    @IBOutlet weak var labelVisibilitySwitch: UISwitch!
    @IBOutlet weak var labelColorPicker: HorizontalColorPicker!
    @IBOutlet weak var labelFormatPicker: HorizontalPicker!
    @IBOutlet weak var labelUnitPicker: HorizontalPicker!
    @IBOutlet weak var labelPositionPicker: HorizontalPicker!
    
    // MARK: - View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Corner radius for parent view
        settingsView.layer.cornerRadius = 10
        
        // Set picker options
        gridTypePicker.options = gridTypes
        labelPositionPicker.options = labelPositions
        labelUnitPicker.options = labelUnits
        labelFormatPicker.options = labelFormats
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        //
        // Setup UI Controls
        setupUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupUI() {
        //
        // Set current grid type
        if let grid = mapView?.grid {
            //
            // Set the grid type
            gridTypePicker.selectedIndex = currentGridType().rawValue
            
            gridVisibilitySwitch.isOn = grid.isVisible
            labelVisibilitySwitch.isOn = grid.labelVisibility
            labelPositionPicker.selectedIndex = grid.labelPosition.rawValue
            
            if grid is AGSLatitudeLongitudeGrid {
                labelFormatPicker.isEnabled = true
                labelFormatPicker.selectedIndex = (grid as! AGSLatitudeLongitudeGrid).labelFormat.rawValue
                labelUnitPicker.isEnabled = false
            }
            else if grid is AGSMGRSGrid {
                labelUnitPicker.isEnabled = true
                labelUnitPicker.selectedIndex = (grid as! AGSMGRSGrid).labelUnit.rawValue
                labelFormatPicker.isEnabled = false
            }
            else if grid is AGSUTMGrid {
                labelUnitPicker.isEnabled = false
                labelFormatPicker.isEnabled = false
            }
            else if grid is AGSUSNGGrid {
                labelUnitPicker.isEnabled = true
                labelUnitPicker.selectedIndex = (grid as! AGSUSNGGrid).labelUnit.rawValue
                labelFormatPicker.isEnabled = false
            }
        }
        
        // Set picker delegates
        gridTypePicker.delegate = self
        labelPositionPicker.delegate = self
        labelUnitPicker.delegate = self
        labelFormatPicker.delegate = self
        gridColorPicker.delegate = self
        labelColorPicker.delegate = self
    }
    
    //MARK: - Actions
    
    @IBAction private func closeAction() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func gridVisibilityAction() {
        mapView?.grid?.isVisible = gridVisibilitySwitch.isOn
    }
    
    @IBAction private func labelVisibilityAction() {
        mapView?.grid?.labelVisibility = labelVisibilitySwitch.isOn
    }
    
    // MARK: - Helper Functions

    private func currentGridType() -> GridType {
        if let grid = mapView?.grid {
            if grid is AGSLatitudeLongitudeGrid {
                return .LatLong
            }
            else if grid is AGSMGRSGrid {
                return .MGRS
            }
            else if grid is AGSUTMGrid {
                return .UTM
            }
            else if grid is AGSUSNGGrid {
                return .USNG
            }
        }
        return .LatLong
    }
    
    private func changeGrid() {
        //
        //
        var grid: AGSGrid?
        
        let gridType = gridTypePicker.options[gridTypePicker.selectedIndex]
        if (gridType == "LatLong") {
            grid = AGSLatitudeLongitudeGrid()
            labelFormatPicker.isEnabled = true
            labelUnitPicker.isEnabled = false
        }
        else if (gridType == "MGRS") {
            grid = AGSMGRSGrid()
            labelUnitPicker.isEnabled = true
            labelFormatPicker.isEnabled = false
        }
        else if (gridType == "UTM") {
            grid = AGSUTMGrid()
            labelUnitPicker.isEnabled = false
            labelFormatPicker.isEnabled = false
        }
        else if (gridType == "USNG") {
            grid = AGSUSNGGrid()
            labelUnitPicker.isEnabled = true
            labelFormatPicker.isEnabled = false
        }
        
        // Set selected grid
        mapView?.grid = grid
        
        // Apply settings to selected grid
        gridVisibilityAction()
        labelVisibilityAction()
        changeLabelPosition()
        changeLabelFormat()
        changeLabelUnit()
        
        if let selectedColor = gridColorPicker.selectedColor {
            changeGrid(color: selectedColor)
        }
        
        if let selectedColor = labelColorPicker.selectedColor {
            changeLabel(color: selectedColor)
        }
    }
    
    // Change the grid color
    private func changeGrid(color: UIColor) {
        if let grid = mapView?.grid {
            let gridLevels = grid.levelCount
            for gridLevel in 0...gridLevels-1 {
                let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: color, width: CGFloat(gridLevel+1))
                grid.setLineSymbol(lineSymbol, forLevel: gridLevel)
            }
        }
    }
    
    // Change the grid label color
    private func changeLabel(color: UIColor) {
        if let grid = mapView?.grid {
            let gridLevels = grid.levelCount
            for gridLevel in 0...gridLevels-1 {
                let textSymbol = AGSTextSymbol()
                textSymbol.color = color
                textSymbol.size = 14
                textSymbol.horizontalAlignment = .left
                textSymbol.verticalAlignment = .bottom
                textSymbol.haloColor = UIColor.white
                textSymbol.haloWidth = CGFloat(gridLevel+1)
                grid.setTextSymbol(textSymbol, forLevel: gridLevel)
            }
        }
    }
    
    // Change the grid label position
    private func changeLabelPosition() {
        mapView?.grid?.labelPosition = AGSGridLabelPosition(rawValue: labelPositionPicker.selectedIndex)!
    }
    
    // Change the grid label format
    private func changeLabelFormat() {
        if mapView?.grid is AGSLatitudeLongitudeGrid {
            (mapView?.grid as! AGSLatitudeLongitudeGrid).labelFormat = AGSLatitudeLongitudeGridLabelFormat(rawValue: labelFormatPicker.selectedIndex)!
        }
    }
    
    // Change the grid label unit
    private func changeLabelUnit() {
        if mapView?.grid is AGSMGRSGrid {
            (mapView?.grid as! AGSMGRSGrid).labelUnit = AGSMGRSGridLabelUnit(rawValue: labelUnitPicker.selectedIndex)!
        }
        else if mapView?.grid is AGSUSNGGrid {
            (mapView?.grid as! AGSUSNGGrid).labelUnit = AGSUSNGGridLabelUnit(rawValue: labelUnitPicker.selectedIndex)!
        }
    }
    
    // MARK: Horizontal Picker Delegate
    
    internal func horizontalPicker(_ horizontalPicker: HorizontalPicker, didUpdateSelectedIndex index: Int) {
        if horizontalPicker == gridTypePicker {
            changeGrid()
        }
        else if horizontalPicker == labelPositionPicker {
            changeLabelPosition()
        }
        else if horizontalPicker == labelFormatPicker {
            changeLabelFormat()
        }
        else if horizontalPicker == labelUnitPicker {
            changeLabelUnit()
        }
    }
    
    // MARK: Horizontal Color Picker Delegate

    func horizontalColorPicker(_ horizontalColorPicker: HorizontalColorPicker, didUpdateSelectedColor selectedColor: UIColor) {
        if horizontalColorPicker == gridColorPicker {
            changeGrid(color: selectedColor)
        }
        else if horizontalColorPicker == labelColorPicker {
            changeLabel(color: selectedColor)
        }
    }
}
