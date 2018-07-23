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

protocol EAOptionsVCDelegate:class {
    func optionsViewController(_ optionsViewController:EAOptionsViewController, didSelectOptionAtIndex index:Int)
}

class EAOptionsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIBarPositioningDelegate {
    
    @IBOutlet private weak var tableView:UITableView!
    
    var options:[String]!
    weak var delegate:EAOptionsVCDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    //MARK:- Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.options?.count ?? 0
    }
    
    //MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EAOptionsCell", for: indexPath)
        
        cell.textLabel?.text = self.options[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate.optionsViewController(self, didSelectOptionAtIndex: indexPath.row)
        self.cancelAction()
    }
    
    //MARK: - Actions
    
    @IBAction func cancelAction() {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - UIBarPositioningDelegate
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
