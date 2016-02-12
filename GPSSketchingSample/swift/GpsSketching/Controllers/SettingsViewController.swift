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
import ArcGIS

class SettingsViewController: UIViewController {

    //used for setting the frequency distance in meters for the location updates.
    @IBOutlet weak var frequencyControl:UISegmentedControl!
    
    //used for setting the accuracy in meters for the location updates.
    @IBOutlet weak var accuracyControl:UISegmentedControl!
    
    //used to store the possible values for accuracy and freqeuncy
    var accuracyValues:[Double]!
    var frequencyValues:[Double]!
    
    var parameters:Parameters!
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.accuracyValues = [kCLLocationAccuracyBest, kCLLocationAccuracyNearestTenMeters, kCLLocationAccuracyHundredMeters, kCLLocationAccuracyKilometer]
        self.frequencyValues = [1.0, 10.0, 100.0, 1000.0]
        
        //update segment control selection based on the parameter object
        
        if let accuracyIndex = self.accuracyValues.indexOf(self.parameters.accuracyValue) {
            self.accuracyControl.selectedSegmentIndex = accuracyIndex
        }
        if let frequencyIndex = self.frequencyValues.indexOf(self.parameters.frequencyValue) {
            self.frequencyControl.selectedSegmentIndex = frequencyIndex
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //MARK: - Actions
    
    @IBAction func done(sender:AnyObject) {
        self.dismissViewControllerAnimated(true, completion:nil)
    }
    
    @IBAction func controlChanged(sender:UISegmentedControl) {
        //set the appropriate value in the settings dict according to the selection.
        if sender == self.frequencyControl {
            self.parameters.frequencyValue = self.frequencyValues[self.frequencyControl.selectedSegmentIndex]
        }
        
        //set the appropriate value in the settings dict according to the selection.
        if sender == self.accuracyControl {
            self.parameters.accuracyValue = self.accuracyValues[self.accuracyControl.selectedSegmentIndex]
        }
    }
}
