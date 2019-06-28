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
    var mapView: AGSMapView? {
        didSet {
            if isViewLoaded {
                updateUIForGrid()
            }
        }
    }
    
    private let labelPositionLabels = ["Geographic", "Bottom Left", "Bottom Right", "Top Left", "Top Right", "Center", "All Sides"]
    private let labelUnitLabels = ["Kilometers Meters", "Meters"]
    private let labelFormatLabels = ["Decimal Degrees", "Degrees Minutes Seconds"]
    
    @IBOutlet private weak var gridVisibilitySwitch: UISwitch?
    @IBOutlet private weak var labelVisibilitySwitch: UISwitch?
    
    @IBOutlet private weak var gridTypeCell: UITableViewCell?
    @IBOutlet private weak var gridColorCell: UITableViewCell?
    
    @IBOutlet private weak var labelFormatCell: UITableViewCell?
    @IBOutlet private weak var labelUnitCell: UITableViewCell?
    @IBOutlet private weak var labelPositionCell: UITableViewCell?
    @IBOutlet private weak var labelColorCell: UITableViewCell?
    
    @IBOutlet private weak var gridColorSwatchView: UIView?
    @IBOutlet private weak var labelColorSwatchView: UIView?
    
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
    
    private func makeGrid(type: GridType) -> AGSGrid {
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
        
        // set corner radius and border for color swatches
        for swatch in [gridColorSwatchView, labelColorSwatchView] {
            swatch?.layer.cornerRadius = 5
            swatch?.layer.borderColor = UIColor(hue: 0, saturation: 0, brightness: 0.9, alpha: 1).cgColor
            swatch?.layer.borderWidth = 1
        }

        // Setup UI Controls
        updateUIForGrid()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // set the colors redundantly to avoid a visual glitch when closing the color picker
        updateUIForGridColor()
        updateUIForLabelColor()
    }
    
    private func updateUIForGrid() {
        // Set current grid type
        guard let grid = mapView?.grid,
            let gridType = GridType(grid: grid) else {
            return
        }

        gridTypeCell?.detailTextLabel?.text = gridType.label
        
        gridVisibilitySwitch?.isOn = grid.isVisible
        labelVisibilitySwitch?.isOn = grid.labelVisibility
        
        labelPositionCell?.detailTextLabel?.text = labelPositionLabels[grid.labelPosition.rawValue]
        
        updateLabelFormatUI()
        updateLabelUnitUI()
        updateUIForGridColor()
        updateUIForLabelColor()
    }
    
    private func updateLabelFormatUI() {
        if let grid = mapView?.grid as? AGSLatitudeLongitudeGrid {
            labelFormatCell?.detailTextLabel?.text = labelFormatLabels[grid.labelFormat.rawValue]
            labelFormatCell?.detailTextLabel?.isEnabled = true
            labelFormatCell?.selectionStyle = .default
        } else {
            labelFormatCell?.detailTextLabel?.text = "N/A"
            labelFormatCell?.detailTextLabel?.isEnabled = false
            labelFormatCell?.selectionStyle = .none
        }
    }
    
    private func updateLabelUnitUI() {
        if let grid = mapView?.grid,
            let labelUnitID = (grid as? AGSMGRSGrid)?.labelUnit.rawValue ?? (grid as? AGSUSNGGrid)?.labelUnit.rawValue {
            labelUnitCell?.detailTextLabel?.text = labelUnitLabels[labelUnitID]
            labelUnitCell?.detailTextLabel?.isEnabled = true
            labelUnitCell?.selectionStyle = .default
        } else {
            labelUnitCell?.detailTextLabel?.text = "N/A"
            labelUnitCell?.detailTextLabel?.isEnabled = false
            labelUnitCell?.selectionStyle = .none
        }
    }
    
    private func updateUIForGridColor() {
        if let grid = mapView?.grid {
            gridColorSwatchView?.backgroundColor = gridColor(of: grid)
        }
    }
    
    private func updateUIForLabelColor() {
        if let grid = mapView?.grid {
            labelColorSwatchView?.backgroundColor = labelColor(of: grid)
        }
    }
    
    // MARK: - Helpers
    
    /// Creates a new grid object based on the type, applies the common configuration
    /// from the existing grid, and adds it to the map view.
    private func changeGrid(to newGridType: GridType) {
        guard let displayedGrid = mapView?.grid,
            // don't replace the grid if it already has the target type
            GridType(grid: displayedGrid) != newGridType else {
            return
        }
        
        // create a new grid object based on the type
        let newGrid = makeGrid(type: newGridType)
        
        // apply the common settings of the exiting grid to the new grid
        newGrid.labelPosition = displayedGrid.labelPosition
        newGrid.labelVisibility = displayedGrid.labelVisibility
        newGrid.isVisible = displayedGrid.isVisible
        if let gridColor = gridColor(of: displayedGrid) {
            changeGridColor(of: newGrid, to: gridColor)
        }
        if let labelColor = labelColor(of: displayedGrid) {
            changeLabelColor(of: newGrid, to: labelColor)
        }
        
        // set the newly-created grid as the map view's grid
        mapView?.grid = newGrid
        
        // update the UI in case the
        updateUIForGrid()
    }
    
    // MARK: - Actions
    
    @IBAction func gridVisibilityAction(_ sender: UISwitch) {
        mapView?.grid?.isVisible = sender.isOn
    }
    
    @IBAction func labelVisibilityAction(_ sender: UISwitch) {
        mapView?.grid?.labelVisibility = sender.isOn
    }
    
    // MARK: - Colors
    
    private func gridColor(of grid: AGSGrid) -> UIColor? {
        guard let lineSymbol = grid.lineSymbol(forLevel: 0) as? AGSLineSymbol else {
            return nil
        }
        return lineSymbol.color
    }
    
    private func labelColor(of grid: AGSGrid) -> UIColor? {
        guard let textSymbol = grid.textSymbol(forLevel: 0) as? AGSTextSymbol else {
            return nil
        }
        return textSymbol.color
    }
    
    /// Changes the grid color.
    private func changeGridColor(of grid: AGSGrid, to color: UIColor) {
        for gridLevel in 0..<grid.levelCount {
            let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: color, width: CGFloat(gridLevel + 1))
            grid.setLineSymbol(lineSymbol, forLevel: gridLevel)
        }
    }
    
    /// Changes the grid label color.
    private func changeLabelColor(of grid: AGSGrid, to color: UIColor) {
        for gridLevel in 0..<grid.levelCount {
            let textSymbol = AGSTextSymbol()
            textSymbol.color = color
            textSymbol.size = 14
            textSymbol.horizontalAlignment = .left
            textSymbol.verticalAlignment = .bottom
            textSymbol.haloColor = .white
            textSymbol.haloWidth = CGFloat(gridLevel + 1)
            grid.setTextSymbol(textSymbol, forLevel: gridLevel)
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView.cellForRow(at: indexPath) {
        case gridTypeCell:
            showGridTypePicker()
        case labelPositionCell:
            showLabelPositionPicker()
        case labelFormatCell:
            showLabelFormatPicker()
        case labelUnitCell:
            showLabelUnitPicker()
        case gridColorCell:
            showGridColorPicker()
        case labelColorCell:
            showLabelColorPicker()
        default:
            break
        }
    }
    
    private func showLabelPositionPicker() {
        guard let grid = mapView?.grid else {
            return
        }
        let selectedIndex = grid.labelPosition.rawValue
        let optionsViewController = OptionsTableViewController(labels: labelPositionLabels, selectedIndex: selectedIndex) { (newIndex) in
            self.mapView?.grid?.labelPosition = AGSGridLabelPosition(rawValue: newIndex)!
        }
        optionsViewController.title = "Position"
        show(optionsViewController, sender: self)
    }
    
    private func showLabelFormatPicker() {
        guard let grid = mapView?.grid,
            let selectedIndex = (grid as? AGSLatitudeLongitudeGrid)?.labelFormat.rawValue else {
            return
        }
        let optionsViewController = OptionsTableViewController(labels: labelFormatLabels, selectedIndex: selectedIndex) { (newIndex) in
            if let grid = self.mapView?.grid as? AGSLatitudeLongitudeGrid {
                grid.labelFormat = AGSLatitudeLongitudeGridLabelFormat(rawValue: newIndex)!
                self.updateLabelFormatUI()
            }
        }
        optionsViewController.title = "Format"
        show(optionsViewController, sender: self)
    }
    
    private func showLabelUnitPicker() {
        guard let grid = mapView?.grid,
            let selectedIndex = (grid as? AGSUSNGGrid)?.labelUnit.rawValue ?? (grid as? AGSMGRSGrid)?.labelUnit.rawValue else {
            return
        }
        let optionsViewController = OptionsTableViewController(labels: labelUnitLabels, selectedIndex: selectedIndex) { (newIndex) in
            if let grid = self.mapView?.grid as? AGSMGRSGrid {
                grid.labelUnit = AGSMGRSGridLabelUnit(rawValue: newIndex)!
            } else if let grid = self.mapView?.grid as? AGSUSNGGrid {
                grid.labelUnit = AGSUSNGGridLabelUnit(rawValue: newIndex)!
            }
            self.updateLabelUnitUI()
        }
        optionsViewController.title = "Unit"
        show(optionsViewController, sender: self)
    }
    
    private func showGridTypePicker() {
        guard let grid = mapView?.grid,
            let gridType = GridType(grid: grid) else {
            return
        }
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
    
    private func showGridColorPicker() {
        guard let grid = mapView?.grid,
            let color = gridColor(of: grid) else {
            return
        }
        let controller = ColorPickerViewController.instantiateWith(color: color) { (color) in
            self.changeGridColor(of: grid, to: color)
            self.updateUIForGridColor()
        }
        controller.title = "Grid Color"
        show(controller, sender: self)
    }
    
    private func showLabelColorPicker() {
        guard let grid = mapView?.grid,
            let color = labelColor(of: grid) else {
            return
        }
        let controller = ColorPickerViewController.instantiateWith(color: color) { (color) in
            self.changeLabelColor(of: grid, to: color)
            self.updateUIForLabelColor()
        }
        controller.title = "Label Color"
        show(controller, sender: self)
    }
}
