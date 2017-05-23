//
//  ServiceAreaSettingsVC.swift
//  arcgis-ios-sdk-samples
//
//  Created by Gagandeep Singh on 5/23/17.
//  Copyright © 2017 Esri. All rights reserved.
//

import UIKit

protocol ServiceAreaSettingsVCDelegate:class {
    
    func serviceAreaSettingsVC(_ serviceAreaSettingsVC:ServiceAreaSettingsVC, didUpdateFirstTimeBreak timeBreak:Int)
    
    func serviceAreaSettingsVC(_ serviceAreaSettingsVC:ServiceAreaSettingsVC, didUpdateSecondTimeBreak timeBreak:Int)
}

class ServiceAreaSettingsVC: UIViewController {

    @IBOutlet private var firstTimeBreakSlider:UISlider!
    @IBOutlet private var secondTimeBreakSlider:UISlider!
    @IBOutlet private var firstTimeBreakLabel:UILabel!
    @IBOutlet private var secondTimeBreakLabel:UILabel!
    
    weak var delegate:ServiceAreaSettingsVCDelegate?
    
    var firstTimeBreak:Int = 3
    var secondTimeBreak:Int = 8
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.firstTimeBreakLabel.text = "\(self.firstTimeBreak)"
        self.secondTimeBreakLabel.text = "\(self.secondTimeBreak)"
        
        self.firstTimeBreakSlider.value = Float(self.firstTimeBreak)
        self.secondTimeBreakSlider.value = Float(self.secondTimeBreak)
    }
    
    //MARK: - Actions
    
    @IBAction private func sliderValueChanged(sender:UISlider) {
        
        if sender == self.firstTimeBreakSlider {
            
            self.firstTimeBreakLabel.text = "\(Int(sender.value))"
            
            self.delegate?.serviceAreaSettingsVC(self, didUpdateFirstTimeBreak: Int(sender.value))
        }
        else {
            
            self.secondTimeBreakLabel.text = "\(Int(sender.value))"
            
            self.delegate?.serviceAreaSettingsVC(self, didUpdateSecondTimeBreak: Int(sender.value))
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
