//
// Copyright 2016 Esri.
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

class GridSettingsViewController: UITableViewController {
    @IBOutlet var colorSwatch: UIView?
    @IBOutlet var lineColorSwatch: UIView?
    
    @IBOutlet var lineWidthSlider: UISlider?
    @IBOutlet var gridSizeSlider: UISlider?
    @IBOutlet var lineWidthLabel: UILabel?
    @IBOutlet var gridSizeLabel: UILabel?
    
    @IBOutlet weak var colorCell: UITableViewCell!
    @IBOutlet weak var gridLineColorCell: UITableViewCell!
    
    weak var backgroundGrid: AGSBackgroundGrid? {
        didSet {
            updateUIForBackgroundGrid()
        }
    }

    private let numberFormatter = NumberFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set corner radius and border for color swatches
        for swatch in [colorSwatch, lineColorSwatch] {
            swatch?.layer.cornerRadius = 5
            swatch?.layer.borderColor = UIColor(hue: 0, saturation: 0, brightness: 0.9, alpha: 1).cgColor
            swatch?.layer.borderWidth = 1
        }
        
        updateUIForBackgroundGrid()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // set the colors redundantly to avoid a visual glitch when closing the color picker
        updateUIForGridColor()
        updateUIForGridLineColor()
    }
    
    private func updateUIForBackgroundGrid() {
        updateUIForGridColor()
        updateUIForGridLineColor()
        updateUIForGridLineWidth()
        updateUIForGridSize()
    }
    
    private func updateUIForGridColor() {
        colorSwatch?.backgroundColor = backgroundGrid?.color
    }
    private func updateUIForGridLineColor() {
        lineColorSwatch?.backgroundColor = backgroundGrid?.gridLineColor
    }
    private func updateUIForGridLineWidth() {
        guard let value = backgroundGrid?.gridLineWidth else {
            return
        }
        lineWidthLabel?.text = numberFormatter.string(from: value as NSNumber)
        lineWidthSlider?.value = Float(value)
    }
    private func updateUIForGridSize() {
        guard let value = backgroundGrid?.gridSize else {
            return
        }
        gridSizeLabel?.text = numberFormatter.string(from: value as NSNumber)
        gridSizeSlider?.value = Float(value)
    }
    
    // MARK: - Actions
    
    @IBAction private func lineWidthSliderChanged(_ sender: UISlider) {
        backgroundGrid?.gridLineWidth = Double(sender.value)
        updateUIForGridLineWidth()
    }
    
    @IBAction private func gridSizeSliderChanged(_ sender: UISlider) {
        backgroundGrid?.gridSize = Double(sender.value)
        updateUIForGridSize()
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        switch cell {
        case colorCell:
            guard let color = backgroundGrid?.color else {
                return
            }
            let controller = ColorPickerViewController.instantiateWith(color: color) { (color) in
                self.backgroundGrid?.color = color
                self.updateUIForGridColor()
            }
            controller.title = "Color"
            show(controller, sender: self)
        case gridLineColorCell:
            guard let color = backgroundGrid?.gridLineColor else {
                return
            }
            let controller = ColorPickerViewController.instantiateWith(color: color) { (color) in
                self.backgroundGrid?.gridLineColor = color
                self.updateUIForGridLineColor()
            }
            controller.title = "Line Color"
            show(controller, sender: self)
        default:
            break
        }
    }
}
