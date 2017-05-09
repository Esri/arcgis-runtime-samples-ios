//
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

protocol AttributeValuesVCDelegate:class {
    
    func attributeValuesViewController(_ attributeValuesViewController:AttributeValuesViewController, didSelectValue value:String)
}

class AttributeValuesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var attributeValues:[String]!
    
    weak var delegate:AttributeValuesVCDelegate?

    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.attributeValues?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttributeValueCell")!
        cell.textLabel?.text = self.attributeValues[indexPath.row]
        
        return cell
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //dismiss view controller
        self.dismiss(animated: true, completion: nil)
        
        let selectedValue = self.attributeValues[indexPath.row]
        self.delegate?.attributeValuesViewController(self, didSelectValue: selectedValue)
    }
    
    //MARK: - Actions
    
    @IBAction private func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
