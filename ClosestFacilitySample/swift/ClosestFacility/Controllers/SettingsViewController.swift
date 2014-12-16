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
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var facilityCountLabel:UILabel!
    @IBOutlet weak var cutoffTimeLabel:UILabel!
    @IBOutlet weak var facilityCountSlider:UISlider!
    @IBOutlet weak var cutOffTimeSlider:UISlider!
    
    var parameters:Parameters!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //reflect default values in sliders
        self.facilityCountSlider.value = Float(self.parameters.facilityCount)
        self.facilityCountLabel.text = "\(Int(self.parameters.facilityCount))"
        
        self.cutOffTimeSlider.value = Float(self.parameters.cutoffTime)
        self.cutoffTimeLabel.text = "\(Int(self.parameters.cutoffTime))"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Action Methods
    
    @IBAction func facilityCountChanged(facilityCountSlider:UISlider) {
        self.parameters.facilityCount = Int(facilityCountSlider.value)
        self.facilityCountLabel.text = "\(self.parameters.facilityCount)"
    }
    
    
    @IBAction func cutoffTimeChanged(cutoffTimeSlider:UISlider) {
        self.parameters.cutoffTime = Double(cutoffTimeSlider.value)
        self.cutoffTimeLabel.text = "\(Int(self.parameters.cutoffTime))"
    }
    
    @IBAction func done(sender:AnyObject) {
        self.dismissViewControllerAnimated(true, completion:nil)
    }
    
}
