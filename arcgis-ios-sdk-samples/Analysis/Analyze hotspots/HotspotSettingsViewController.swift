// Copyright 2017 Esri.
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

protocol HotspotSettingsVCDelegate: AnyObject {
    
    func hotspotSettingsViewController(_ hotspotSettingsViewController: HotspotSettingsViewController, didSelectDates fromDate: String, toDate: String)
}

class HotspotSettingsViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet var fromTextField: UITextField!
    @IBOutlet var toTextField: UITextField!
    
    private var datePicker: UIDatePicker!
    private var dateFormatter: DateFormatter!
    
    private var selectedTextField: UITextField!
    
    weak var delegate: HotspotSettingsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //create date formatter to format dates for input
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        //will use date picker as the input accessory for the textfields
        self.datePicker = UIDatePicker()
        self.datePicker.datePickerMode = .date
        self.datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.numberOfTouchesRequired = 1
        self.view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    //MARK: - Actions
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        self.selectedTextField.text = self.dateFormatter.string(from: sender.date)
    }
    
    @objc func tapAction() {
        self.view.endEditing(true)
    }
    
    @IBAction func analyzeAction() {
        self.view.endEditing(true)
        
        if !self.toTextField.text!.isEmpty && !self.fromTextField.text!.isEmpty {
            self.delegate?.hotspotSettingsViewController(self, didSelectDates: self.fromTextField.text!, toDate: self.toTextField.text!)
        }
        else {
            presentAlert(message: "Both dates are required")
        }
    }
    
    //MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.selectedTextField = textField
        if textField == self.fromTextField {
            self.datePicker.minimumDate = self.dateFormatter.date(from: "1998-01-01")
            self.datePicker.maximumDate = self.dateFormatter.date(from: "1998-05-29")
        }
        else {
            if let dateString = self.fromTextField.text , !dateString.isEmpty {
                self.datePicker.minimumDate = self.dateFormatter.date(from: dateString)?.addingTimeInterval(2 * 60 * 60 * 24)
            }
            else {
                self.datePicker.minimumDate = self.dateFormatter.date(from: "1998-01-01")
            }
            self.datePicker.maximumDate = self.dateFormatter.date(from: "1998-05-31")
        }
        self.datePicker.date = self.datePicker.minimumDate!
        textField.text = self.dateFormatter.string(from: self.datePicker.date)
        textField.inputView = self.datePicker
    }
}
