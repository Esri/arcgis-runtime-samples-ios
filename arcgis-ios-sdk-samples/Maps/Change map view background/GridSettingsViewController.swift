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

enum ColorPickerToggle: String {
    case On = "On"
    case Off = "Off"
}

enum AnimationDirection: String {
    case Forward = "Forward"
    case Backward = "Backward"
}

protocol GridSettingsVCDelegate: AnyObject {
    
    func gridSettingsViewController(_ gridSettingsViewController: GridSettingsViewController, didUpdateBackgroundGrid grid: AGSBackgroundGrid)
    
    func gridSettingsViewControllerWantsToClose(_ gridSettingsViewController: GridSettingsViewController)
}

class GridSettingsViewController: UIViewController {
    
    @IBOutlet var settingsView: UIView!
    @IBOutlet var settingsTopContraint: NSLayoutConstraint!
    @IBOutlet var colorButton: UIButton!
    @IBOutlet var lineColorButton: UIButton!
    @IBOutlet var lineWidthSlider: UISlider!
    @IBOutlet var gridSizeSlider: UISlider!
    @IBOutlet var lineWidthLabel: UILabel!
    @IBOutlet var gridSizeLabel: UILabel!
    
    @IBOutlet var colorPickerView: UIView!
    @IBOutlet var colorView: UIView!
    @IBOutlet var hueSlider: UISlider!
    @IBOutlet var saturationSlider: UISlider!
    @IBOutlet var brightnessSlider: UISlider!
    @IBOutlet var hueLabel: UILabel!
    @IBOutlet var saturationLabel: UILabel!
    @IBOutlet var brightnessLabel: UILabel!
    
    private var selectedColorButton: UIButton!
    
    weak var delegate: GridSettingsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.toggleColorPicker(.Off, animated: false, animationDirection: .Forward)
        
        self.stylizeUI()
    }
    
    private func stylizeUI() {
        let buttonColor = UIColor(red: 0, green: 122.0/255.0, blue: 1, alpha: 1)
        
        //corner radius and border for color buttons and view
        self.colorButton.layer.cornerRadius = 5
        self.colorButton.layer.borderColor = buttonColor.cgColor
        self.colorButton.layer.borderWidth = 1
        
        self.lineColorButton.layer.cornerRadius = 5
        self.lineColorButton.layer.borderColor = buttonColor.cgColor
        self.lineColorButton.layer.borderWidth = 1
        
        self.colorView.layer.cornerRadius = 5
        self.colorView.layer.borderColor = UIColor.lightGray.cgColor
        self.colorView.layer.borderWidth = 1
        
        //corner radius for parent views
        self.settingsView.layer.cornerRadius = 10
        self.colorPickerView.layer.cornerRadius = 10
    }
    
    //MARK: - Actions
    
    @IBAction private func colorButtonsAction(_ sender: UIButton) {
        //keep a reference to selected button to later update the color
        self.selectedColorButton = sender.tag == 0 ? self.colorButton : self.lineColorButton
        
        //get the current color of the button tapped
        var h: CGFloat = 0.0
        var s: CGFloat = 0.0
        var b: CGFloat = 0.0
        sender.backgroundColor?.getHue(&h, saturation: &s, brightness: &b, alpha: nil)
        
        //set the color on color view
        self.colorView.backgroundColor = sender.backgroundColor
        
        //update the sliders
        self.hueSlider.value = Float(h) * 255.0
        self.saturationSlider.value = Float(s) * 255.0
        self.brightnessSlider.value = Float(b) * 255.0
        
        //update slider labels
        self.hueLabel.text = "\(Int(self.hueSlider.value))"
        self.saturationLabel.text = "\(Int(self.saturationSlider.value))"
        self.brightnessLabel.text = "\(Int(self.brightnessSlider.value))"
        
        //show color picker view
        self.toggleColorPicker(.On, animated: true, animationDirection: .Forward)
    }
    
    @IBAction private func lineWidthSliderChanged(_ sender: UISlider) {
        //update label
        self.lineWidthLabel.text = "\(Int(sender.value))"
        
        //update map view
        self.updateMapView()
    }
    
    @IBAction private func gridSizeSliderChanged(_ sender: UISlider) {
        //update label
        self.gridSizeLabel.text = "\(Int(sender.value))"
        
        //update map view
        self.updateMapView()
    }
    
    @IBAction private func HSBSlidersChanged(_ slider: UISlider) {
        switch slider.tag {
        case 0:
            self.hueLabel.text = "\(Int(slider.value))"
        case 1:
            self.saturationLabel.text = "\(Int(slider.value))"
        default:
            self.brightnessLabel.text = "\(Int(slider.value))"
        }
        
        //update color view background color
        let h = CGFloat(self.hueSlider.value) / 255.0
        let s = CGFloat(self.saturationSlider.value) / 255.0
        let b = CGFloat(self.brightnessSlider.value) / 255.0
        
        let newColor = UIColor(hue: h, saturation: s, brightness: b, alpha: 1)
        self.colorView.backgroundColor = newColor
    }
    
    @IBAction private func doneAction() {
        //assign color to the button
        self.selectedColorButton.backgroundColor = self.colorView.backgroundColor
        
        //hide color picker view
        self.toggleColorPicker(.Off, animated: true, animationDirection: .Backward)
        
        //update map view
        self.updateMapView()
    }
    
    @IBAction private func closeAction() {
        self.delegate?.gridSettingsViewControllerWantsToClose(self)
    }
    
    //TODO: Remove this work around once able to change properties on grid
    private func updateMapView() {
        
        let backgroundGrid = AGSBackgroundGrid(color: self.colorButton.backgroundColor!, gridLineColor: self.lineColorButton.backgroundColor!, gridLineWidth: Double(self.lineWidthSlider.value), gridSize: Double(self.gridSizeSlider.value))
        
        //notify delegate
        self.delegate?.gridSettingsViewController(self, didUpdateBackgroundGrid: backgroundGrid)
    }
    
    //MARK: - Color picker show/hide
    
    private func toggleColorPicker(_ toggle: ColorPickerToggle, animated: Bool, animationDirection: AnimationDirection) {
        
        //update the layout constraint to bring the required view on screen
        self.settingsTopContraint.constant = toggle == .On ? -190 : 5
        
        if !animated {
            self.view.layoutIfNeeded()
        }
        else {
            //frames for starting and finishing animation
            let buttonFrame = self.selectedColorButton.frame.offsetBy(dx: 5, dy: 5)
            let colorViewFrame = self.colorView.frame.offsetBy(dx: 5, dy: 5)
            
            //create a temporary view for animation
            let animatingView = UIView(frame: animationDirection == .Forward ? buttonFrame : colorViewFrame)
            animatingView.backgroundColor = animationDirection == .Forward ? self.selectedColorButton.backgroundColor : self.colorView.backgroundColor
            animatingView.layer.cornerRadius = 5
            self.view.addSubview(animatingView)
            
            //hide the button and the view during animation
            self.selectedColorButton.isHidden = true
            self.colorView.isHidden = true
            
            //animate the frames over time
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                
                animatingView.frame = animationDirection == .Forward ? colorViewFrame : buttonFrame
                self?.view.layoutIfNeeded()
                
                }, completion: { [weak self] (finished) in
                    
                    //On completion unhide the original views
                    self?.selectedColorButton.isHidden = false
                    self?.colorView.isHidden = false
                    
                    //remove the animating view from the view hierarchy
                    animatingView.removeFromSuperview()
                })
        }
    }
}
