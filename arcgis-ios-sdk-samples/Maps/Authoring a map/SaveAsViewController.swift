// Copyright 2015 Esri.
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

protocol SaveAsVCDelegate:class {
    func saveAsViewController(saveAsViewController:SaveAsViewController, didInitiateSaveWithTitle title:String, tags:[String], itemDescription:String?)
    func saveAsViewControllerDidCancel(saveAsViewController:SaveAsViewController)
}

class SaveAsViewController: UIViewController {
    
    @IBOutlet  weak var titleTextField:UITextField!
    @IBOutlet private weak var tagsTextField:UITextField!
    @IBOutlet private weak var descriptionTextView:UITextView!
    
    weak var delegate:SaveAsVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //stylize description textView
        self.descriptionTextView.layer.cornerRadius = 5
        self.descriptionTextView.layer.borderColor = UIColor(white: 193.0/255.0, alpha: 1.0).CGColor
        self.descriptionTextView.layer.borderWidth = 0.5
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func resetInputFields() {
        self.titleTextField.text = ""
        self.tagsTextField.text = ""
        self.descriptionTextView.text = ""
    }
    
    //MARK: - Actions
    
    @IBAction private func cancelAction() {
        self.delegate?.saveAsViewControllerDidCancel(self)
    }
    
    @IBAction private func saveAction() {
        //Validations
        guard let title = self.titleTextField.text, tags = self.tagsTextField.text else {
            //show error message
            UIAlertView(title: "Error", message: "Title and tags are required fields", delegate: nil, cancelButtonTitle: "Ok").show()
            return
        }
        
        var itemDescription: String?
        var tagsArray = tags.componentsSeparatedByString(",")

        tagsArray = tagsArray.map ({
            $0.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        })
        
        if !self.descriptionTextView.text.isEmpty {
            itemDescription = self.descriptionTextView.text
        }
        
        self.delegate?.saveAsViewController(self, didInitiateSaveWithTitle: title, tags: tagsArray, itemDescription: itemDescription)
    }
}
