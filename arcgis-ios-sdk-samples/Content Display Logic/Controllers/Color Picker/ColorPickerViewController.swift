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

class ColorPickerViewController: UITableViewController {
    
    @IBOutlet weak var hueSlider: UISlider!
    @IBOutlet weak var saturationSlider: UISlider!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var alphaSlider: UISlider!
    
    @IBOutlet weak var hueLabel: UILabel!
    @IBOutlet weak var saturationLabel: UILabel!
    @IBOutlet weak var brightnessLabel: UILabel!
    @IBOutlet weak var alphaLabel: UILabel!
    
    private var color: UIColor {
        set {
            newValue.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        }
        get {
            return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
        }
    }
    private var onUpdate: ((UIColor)->Void)? = nil
    
    private var hue: CGFloat = 0
    private var saturation: CGFloat = 0
    private var brightness: CGFloat = 0
    private var alpha: CGFloat = 1
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUIForColor()
    }

    private func updateUIForColor() {
        hueSlider.value = Float(hue)
        saturationSlider.value = Float(saturation)
        brightnessSlider.value = Float(brightness)
        alphaSlider.value = Float(alpha)
        
        hueLabel.text = numberFormatter.string(from: hue as NSNumber)
        saturationLabel.text = numberFormatter.string(from: saturation as NSNumber)
        brightnessLabel.text = numberFormatter.string(from: brightness as NSNumber)
        alphaLabel.text = numberFormatter.string(from: alpha as NSNumber)
    }
    
    @IBAction func sliderAction(_ sender: UISlider) {
        let value = CGFloat(sender.value)
        switch sender {
        case hueSlider:
            hue = value
        case saturationSlider:
            saturation = value
        case brightnessSlider:
            brightness = value
        case alphaSlider:
            alpha = value
        default:
            break
        }
        onUpdate?(color)
        updateUIForColor()
    }
    
    static func instantiateWith(color: UIColor, onUpdate: @escaping ((UIColor)->Void)) -> ColorPickerViewController {
        let storyboard = UIStoryboard(name: "ColorPicker", bundle: nil)
        let controller = storyboard.instantiateInitialViewController() as! ColorPickerViewController
        controller.color = color
        controller.onUpdate = onUpdate
        return controller
    }
}
