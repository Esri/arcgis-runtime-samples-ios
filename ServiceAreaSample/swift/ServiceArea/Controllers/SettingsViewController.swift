//
// Copyright 2014 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var firstTimeBreakLabel:UILabel!
    @IBOutlet weak var secondTimeBreakLabel:UILabel!
    @IBOutlet weak var firstTimeBreakSlider:UISlider!
    @IBOutlet weak var secondTimeBreakSlider:UISlider!
    
    var parameters:Parameters!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //assign values to the segment controls based on the parameters value
        self.firstTimeBreakSlider.setValue(Float(self.parameters.firstTimeBreak), animated: true)
        self.firstTimeBreakLabel.text = "\(self.parameters.firstTimeBreak)"
        self.secondTimeBreakSlider.setValue(Float(self.parameters.secondTimeBreak), animated:true)
        self.secondTimeBreakLabel.text = "\(self.parameters.secondTimeBreak)"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Action Methods
    
    @IBAction func firstTimeBreakChanged(sender:UISlider) {
        self.parameters.firstTimeBreak = UInt(sender.value)
        self.firstTimeBreakLabel.text = "\(Int(firstTimeBreakSlider.value))"
    }
    
    
    @IBAction func secondTimeBreakChanged(sender:UISlider) {
        self.parameters.secondTimeBreak = UInt(secondTimeBreakSlider.value)
        self.secondTimeBreakLabel.text = "\(Int(secondTimeBreakSlider.value))"
    }
    
    @IBAction func done(sender:AnyObject) {
        self.dismissViewControllerAnimated(true, completion:nil)
    }

}
