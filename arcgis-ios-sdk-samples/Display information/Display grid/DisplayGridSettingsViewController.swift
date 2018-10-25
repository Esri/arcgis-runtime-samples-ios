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

class DisplayGridSettingsViewController: UITableViewController {
    
    var mapView: AGSMapView?
    
    private let labelPositionLabels = ["Geographic", "Bottom Left", "Bottom Right", "Top Left", "Top Right", "Center", "All Sides"]
    private let labelUnitLabels = ["Kilometers Meters", "Meters"]
    private let labelFormatLabels = ["Decimal Degrees", "Degrees Minutes Seconds"]
    
    @IBOutlet private weak var gridColorPicker: HorizontalColorPicker!
    @IBOutlet private weak var labelColorPicker: HorizontalColorPicker!
    
    @IBOutlet private weak var gridVisibilitySwitch: UISwitch!
    @IBOutlet private weak var labelVisibilitySwitch: UISwitch!
    
    @IBOutlet private weak var gridTypeCell: UITableViewCell!
    @IBOutlet private weak var labelFormatCell: UITableViewCell!
    @IBOutlet private weak var labelUnitCell: UITableViewCell!
    @IBOutlet private weak var labelPositionCell: UITableViewCell!
    
    private enum GridType: Int, CaseIterable {
        case latLong, mgrs, utm, usng
        
        init?(grid: AGSGrid) {
            switch grid {
            case is AGSLatitudeLongitudeGrid: self = .latLong
            case is AGSMGRSGrid: self = .mgrs
            case is AGSUTMGrid: self = .utm
            case is AGSUSNGGrid: self = .usng
            default: return nil
            }
        }
        
        var label: String {
            switch self {
            case .latLong: return "LatLong"
            case .mgrs: return "MGRS"
            case .utm: return "UTM"
            case .usng: return "USNG"
            }
        }
        
    }
    
    private func makeGrid(type: GridType)-> AGSGrid {
        switch type {
        case .latLong: return AGSLatitudeLongitudeGrid()
        case .mgrs: return AGSMGRSGrid()
        case .utm: return AGSUTMGrid()
        case .usng: return AGSUSNGGrid()
        }
    }
    
    // MARK: - View Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set picker delegates
        gridColorPicker.delegate = self
        labelColorPicker.delegate = self
        
        // Setup UI Controls
        updateUIForGrid()
    }
    
    private func updateUIForGrid() {
        // Set current grid type
        guard let grid = mapView?.grid,
            let gridType = GridType(grid: grid) else {
            return
        }

        gridTypeCell.detailTextLabel?.text = gridType.label
        
        gridVisibilitySwitch.isOn = grid.isVisible
        labelVisibilitySwitch.isOn = grid.labelVisibility
        
        labelPositionCell.detailTextLabel?.text = labelPositionLabels[grid.labelPosition.rawValue]
        
        updateLabelFormatUI()
        updateLabelUnitUI()
    }
    
    private func updateLabelFormatUI(){
        if let grid = mapView?.grid as? AGSLatitudeLongitudeGrid {
            labelFormatCell.detailTextLabel?.text = labelFormatLabels[grid.labelFormat.rawValue]
            labelFormatCell.detailTextLabel?.isEnabled = true
            labelFormatCell.selectionStyle = .default
        }
        else {
            labelFormatCell.detailTextLabel?.text = "N/A"
            labelFormatCell.detailTextLabel?.isEnabled = false
            labelFormatCell.selectionStyle = .none
        }
    }
    
    private func updateLabelUnitUI(){
        if let grid = mapView?.grid,
            let labelUnitID = (grid as? AGSMGRSGrid)?.labelUnit.rawValue ?? (grid as? AGSUSNGGrid)?.labelUnit.rawValue {
            labelUnitCell.detailTextLabel?.text = labelUnitLabels[labelUnitID]
            labelUnitCell.detailTextLabel?.isEnabled = true
            labelUnitCell.selectionStyle = .default
        }
        else {
            labelUnitCell.detailTextLabel?.text = "N/A"
            labelUnitCell.detailTextLabel?.isEnabled = false
            labelUnitCell.selectionStyle = .none
        }
    }
    
    //MARK: - Actions
    
    @IBAction private func gridVisibilityAction() {
        mapView?.grid?.isVisible = gridVisibilitySwitch.isOn
    }
    
    @IBAction private func labelVisibilityAction() {
        mapView?.grid?.labelVisibility = labelVisibilitySwitch.isOn
    }
    
    // MARK: - Helper Functions
    
    private func changeGrid(to gridType: GridType) {
        
        let priorGrid = mapView!.grid!
        let grid = makeGrid(type: gridType)
        
        // Set the grid
        mapView?.grid = grid
        
        // Apply settings to selected grid
        grid.labelPosition = priorGrid.labelPosition
        grid.labelVisibility = priorGrid.labelVisibility
        grid.isVisible = priorGrid.isVisible
        
        if let selectedColor = gridColorPicker.selectedColor {
            changeGridColor(selectedColor)
        }
        if let selectedColor = labelColorPicker.selectedColor {
            changeLabelColor(selectedColor)
        }
        
        updateUIForGrid()
    }
    
    // Change the grid color
    private func changeGridColor(_ color: UIColor) {
        if let grid = mapView?.grid {
            for gridLevel in 0..<grid.levelCount {
                let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: color, width: CGFloat(gridLevel+1))
                grid.setLineSymbol(lineSymbol, forLevel: gridLevel)
            }
        }
    }
    
    // Change the grid label color
    private func changeLabelColor(_ color: UIColor) {
        if let grid = mapView?.grid {
            for gridLevel in 0..<grid.levelCount {
                let textSymbol = AGSTextSymbol()
                textSymbol.color = color
                textSymbol.size = 14
                textSymbol.horizontalAlignment = .left
                textSymbol.verticalAlignment = .bottom
                textSymbol.haloColor = .white
                textSymbol.haloWidth = CGFloat(gridLevel+1)
                grid.setTextSymbol(textSymbol, forLevel: gridLevel)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        guard let grid = mapView?.grid else {
            return
        }
        switch cell {
        case gridTypeCell:
            if let gridType = GridType(grid: grid) {
                let selectedIndex = gridType.rawValue
                let labels = GridType.allCases.map { (type) -> String in
                    return type.label
                }
                let optionsViewController = OptionsTableViewController(labels: labels, selectedIndex: selectedIndex) { (newIndex) in
                    self.changeGrid(to: GridType(rawValue: newIndex)!)
                }
                optionsViewController.title = "Grid Type"
                show(optionsViewController, sender: self)
            }
        case labelPositionCell:
            let selectedIndex = grid.labelPosition.rawValue
            let optionsViewController = OptionsTableViewController(labels: labelPositionLabels, selectedIndex: selectedIndex) { (newIndex) in
                self.mapView?.grid?.labelPosition = AGSGridLabelPosition(rawValue: newIndex)!
            }
            optionsViewController.title = "Position"
            show(optionsViewController, sender: self)
        case labelFormatCell:
            if let selectedIndex = (grid as? AGSLatitudeLongitudeGrid)?.labelFormat.rawValue {
                let optionsViewController = OptionsTableViewController(labels: labelFormatLabels, selectedIndex: selectedIndex) { (newIndex) in
                    if let grid = self.mapView?.grid as? AGSLatitudeLongitudeGrid {
                        grid.labelFormat = AGSLatitudeLongitudeGridLabelFormat(rawValue: newIndex)!
                        self.updateLabelFormatUI()
                    }
                }
                optionsViewController.title = "Format"
                show(optionsViewController, sender: self)
            }
        case labelUnitCell:
            if let selectedIndex = (grid as? AGSUSNGGrid)?.labelUnit.rawValue ?? (grid as? AGSMGRSGrid)?.labelUnit.rawValue {
                let optionsViewController = OptionsTableViewController(labels: labelUnitLabels, selectedIndex: selectedIndex) { (newIndex) in
                    if let grid = self.mapView?.grid as? AGSMGRSGrid {
                        grid.labelUnit = AGSMGRSGridLabelUnit(rawValue: newIndex)!
                    }
                    else if let grid = self.mapView?.grid as? AGSUSNGGrid {
                        grid.labelUnit = AGSUSNGGridLabelUnit(rawValue: newIndex)!
                    }
                    self.updateLabelUnitUI()
                }
                optionsViewController.title = "Unit"
                show(optionsViewController, sender: self)
            }
        default:
            break
        }
    }
    
}

extension DisplayGridSettingsViewController: HorizontalColorPickerDelegate {
    
    // MARK: Horizontal Color Picker Delegate
    
    func horizontalColorPicker(_ horizontalColorPicker: HorizontalColorPicker, didUpdateSelectedColor selectedColor: UIColor) {
        if horizontalColorPicker == gridColorPicker {
            changeGridColor(selectedColor)
        }
        else if horizontalColorPicker == labelColorPicker {
            changeLabelColor(selectedColor)
        }
    }
}
