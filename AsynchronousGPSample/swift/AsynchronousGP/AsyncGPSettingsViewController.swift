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

import Foundation
import UIKit

class AsyncGPSettingsViewController:UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var materialLabel: UILabel!
    @IBOutlet weak var timeSwitch: UISegmentedControl!
    @IBOutlet weak var spillTypeSwitch: UISegmentedControl!
    @IBOutlet weak var materialPicker: UIPickerView!
    
    var parameters = AsyncGPParameters()
    var materialsArray = ["Anhydrous ammonia", "Boron trifluoride", "Carbon monoxide", "Chlorine", "Coal gas", "Cyanogen", "Ethylene oxide", "Fluorine", "Hydrogen sulphide", "Methyl bromide"]
    
    
    override func viewDidLoad() {
        //update view to show selected material
        
        if let index = self.materialsArray.indexOf(self.parameters.materialType) {
            self.materialPicker.selectRow(index, inComponent: 0, animated: true)
            self.materialLabel.text = self.parameters.materialType
        }
        
        //reflect the current selections
        self.timeSwitch.selectedSegmentIndex = self.parameters.dayOrNightIncident == "Day" ? 0 : 1
        self.spillTypeSwitch.selectedSegmentIndex = self.parameters.largeOrSmallSpill == "Large" ? 0 : 1
    }
    
    //MARK: UIPickerView data source
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.materialsArray.count
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.materialsArray[row]
    }
    
    //MARK: UIPickerDelegate methods
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.materialLabel.text = self.materialsArray[row]
        self.parameters.materialType = self.materialsArray[row]
    }
    
    //MARK: actions
    
    @IBAction func spillTypeChanged(sender: AnyObject) {
        switch self.spillTypeSwitch.selectedSegmentIndex {
        case 0:
                self.parameters.largeOrSmallSpill = "Large"
        default:
                self.parameters.largeOrSmallSpill = "Small"
        }
    }
    
    @IBAction func timeChanged(sender: AnyObject) {
        switch self.timeSwitch.selectedSegmentIndex {
        case 0:
            self.parameters.dayOrNightIncident = "Day"
        default:
            self.parameters.dayOrNightIncident = "Night"
        }
    }
    
    @IBAction func done(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}