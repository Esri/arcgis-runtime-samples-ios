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

protocol HotspotSettingsVCDelegate: class {
    
    func hotspotSettingsViewController(hotspotSettingsViewController: HotspotSettingsViewController, didSelectDates fromDate: String, toDate: String)
}

class HotspotSettingsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var fromTextField: UITextField!
    @IBOutlet var toTextField: UITextField!
    
    private var datePicker: UIDatePicker!
    private var dateFormatter: NSDateFormatter!
    
    private var selectedTextField: UITextField!
    
    weak var delegate: HotspotSettingsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //create date formatter to format dates for input
        self.dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        //will use date picker as the input accessory for the textfields
        self.datePicker = UIDatePicker()
        self.datePicker.datePickerMode = .Date
        self.datePicker.addTarget(self, action: #selector(datePickerValueChanged), forControlEvents: .ValueChanged)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Actions
    
    func datePickerValueChanged(sender: UIDatePicker) {
        self.selectedTextField.text = self.dateFormatter.stringFromDate(sender.date)
    }
    
    func tapAction() {
        self.view.endEditing(true)
    }
    
    @IBAction func analyzeAction() {
        self.view.endEditing(true)
        
        if !self.toTextField.text!.isEmpty && !self.fromTextField.text!.isEmpty {
            self.delegate?.hotspotSettingsViewController(self, didSelectDates: self.fromTextField.text!, toDate: self.toTextField.text!)
        }
        else {
            SVProgressHUD.showErrorWithStatus("Both dates are required", maskType: .Gradient)
        }
    }
    
    //MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.selectedTextField = textField
        if textField == self.fromTextField {
            self.datePicker.minimumDate = self.dateFormatter.dateFromString("1998-01-01")
            self.datePicker.maximumDate = self.dateFormatter.dateFromString("1998-05-29")
        }
        else {
            if let dateString = self.fromTextField.text where !dateString.isEmpty {
                self.datePicker.minimumDate = self.dateFormatter.dateFromString(dateString)?.dateByAddingTimeInterval(2 * 60 * 60 * 24)
            }
            else {
                self.datePicker.minimumDate = self.dateFormatter.dateFromString("1998-01-01")
            }
            self.datePicker.maximumDate = self.dateFormatter.dateFromString("1998-05-31")
        }
        self.datePicker.date = self.datePicker.minimumDate!
        textField.text = self.dateFormatter.stringFromDate(self.datePicker.date)
        textField.inputView = self.datePicker
    }
}
