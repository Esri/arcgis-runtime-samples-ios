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

class ViewshedSettingsVC: UITableViewController {
    weak var viewshed: AGSLocationViewshed? {
        didSet {
            if isViewLoaded {
                updateUIForViewshed()
            }
        }
    }
    
    @IBOutlet weak var headingSlider: UISlider?
    @IBOutlet weak var headingLabel: UILabel?
    
    @IBOutlet weak var pitchSlider: UISlider?
    @IBOutlet weak var pitchLabel: UILabel?
    
    @IBOutlet weak var horizontalAngleSlider: UISlider?
    @IBOutlet weak var horizontalAngleLabel: UILabel?
    
    @IBOutlet weak var verticalAngleSlider: UISlider?
    @IBOutlet weak var verticalAngleLabel: UILabel?
    
    @IBOutlet weak var minDistanceSlider: UISlider?
    @IBOutlet weak var minDistanceLabel: UILabel?
    
    @IBOutlet weak var maxDistanceSlider: UISlider?
    @IBOutlet weak var maxDistanceLabel: UILabel?
    
    @IBOutlet weak var visibleAreaColorSwatch: UIView?
    @IBOutlet weak var obstructedAreaColorSwatch: UIView?
    @IBOutlet weak var frustumOutlineColorSwatch: UIView?
    
    @IBOutlet weak var visibleAreaColorCell: UITableViewCell?
    @IBOutlet weak var obstructedAreaColorCell: UITableViewCell?
    @IBOutlet weak var frustumOutlineColorCell: UITableViewCell?
    
    @IBOutlet weak var frustumOutlineVisibilitySwitch: UISwitch?
    @IBOutlet weak var analysisOverlayVisibilitySwitch: UISwitch?
    
    private let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set corner radius and border for color swatches
        for swatch in [visibleAreaColorSwatch,
                       obstructedAreaColorSwatch,
                       frustumOutlineColorSwatch] {
            swatch?.layer.cornerRadius = 5
            swatch?.layer.borderColor = UIColor(hue: 0, saturation: 0, brightness: 0.9, alpha: 1).cgColor
            swatch?.layer.borderWidth = 1
        }
        
        updateUIForViewshed()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // set the colors redundantly to avoid a visual glitch when closing the color picker
        updateColorUIForViewshed()
    }
    
    private func updateUIForViewshed() {
        guard let viewshed = viewshed else {
            return
        }
        
        analysisOverlayVisibilitySwitch?.isOn = viewshed.isVisible
        frustumOutlineVisibilitySwitch?.isOn = viewshed.isFrustumOutlineVisible
        
        measurementFormatter.unitStyle = .short
        
        headingLabel?.text = measurementFormatter.string(from: Measurement(value: viewshed.heading, unit: UnitAngle.degrees))
        headingSlider?.value = Float(viewshed.heading)
        pitchLabel?.text = measurementFormatter.string(from: Measurement(value: viewshed.pitch, unit: UnitAngle.degrees))
        pitchSlider?.value = Float(viewshed.pitch)
        horizontalAngleLabel?.text = measurementFormatter.string(from: Measurement(value: viewshed.horizontalAngle, unit: UnitAngle.degrees))
        horizontalAngleSlider?.value = Float(viewshed.horizontalAngle)
        verticalAngleLabel?.text = measurementFormatter.string(from: Measurement(value: viewshed.verticalAngle, unit: UnitAngle.degrees))
        verticalAngleSlider?.value = Float(viewshed.verticalAngle)
        
        measurementFormatter.unitStyle = .medium
        
        minDistanceLabel?.text = measurementFormatter.string(from: Measurement(value: viewshed.minDistance, unit: UnitLength.meters))
        minDistanceSlider?.value = Float(viewshed.minDistance)
        maxDistanceLabel?.text = measurementFormatter.string(from: Measurement(value: viewshed.maxDistance, unit: UnitLength.meters))
        maxDistanceSlider?.value = Float(viewshed.maxDistance)
        
        updateColorUIForViewshed()
    }
    
    private func updateColorUIForViewshed() {
        visibleAreaColorSwatch?.backgroundColor = AGSViewshed.visibleColor()
        obstructedAreaColorSwatch?.backgroundColor = AGSViewshed.obstructedColor()
        frustumOutlineColorSwatch?.backgroundColor = AGSViewshed.frustumOutlineColor()
    }
    
    // MARK: - Actions
    
    @IBAction func analysisOverlayVisibilityAction(_ sender: UISwitch) {
        viewshed?.isVisible = sender.isOn
    }
    
    @IBAction func frustumOutlineVisibilityAction(_ sender: UISwitch) {
        viewshed?.isFrustumOutlineVisible = sender.isOn
    }
    
    @IBAction private func sliderValueChanged(sender: UISlider) {
        guard let viewshed = viewshed else {
            return
        }
        
        let value = Double(sender.value)
        switch sender {
        case headingSlider:
            viewshed.heading = value
        case pitchSlider:
            viewshed.pitch = value
        case horizontalAngleSlider:
            viewshed.horizontalAngle = value
        case verticalAngleSlider:
            viewshed.verticalAngle = value
        case minDistanceSlider:
            viewshed.minDistance = value
        case maxDistanceSlider:
            viewshed.maxDistance = value
        default:
            break
        }
        
        updateUIForViewshed()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        switch cell {
        case visibleAreaColorCell:
            let controller = ColorPickerViewController.instantiateWith(color: AGSViewshed.visibleColor()) { (color) in
                AGSViewshed.setVisibleColor(color)
                self.updateColorUIForViewshed()
            }
            controller.title = "Visible Color"
            show(controller, sender: self)
        case obstructedAreaColorCell:
            let controller = ColorPickerViewController.instantiateWith(color: AGSViewshed.obstructedColor()) { (color) in
                AGSViewshed.setObstructedColor(color)
                self.updateColorUIForViewshed()
            }
            controller.title = "Obstructed Color"
            show(controller, sender: self)
        case frustumOutlineColorCell:
            let controller = ColorPickerViewController.instantiateWith(color: AGSViewshed.frustumOutlineColor()) { (color) in
                AGSViewshed.setFrustumOutlineColor(color)
                self.updateColorUIForViewshed()
            }
            controller.title = "Frustum Color"
            show(controller, sender: self)
        default:
            break
        }
    }
}
