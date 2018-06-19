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

class SegmentedViewController: UIViewController {
    
    @IBOutlet private weak var segmentedControl:UISegmentedControl!
    @IBOutlet private weak var infoContainerView:UIView!
    @IBOutlet private weak var codeContainerView:UIView!
    
    private var sourceCodeVC:SourceCodeViewController!
    private var sampleInfoVC:SampleInfoViewController!
    
    var filenames:[String]!
    var folderName:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SourceCodeSegue" {
            let controller = segue.destination as! SourceCodeViewController
            controller.filenames = self.filenames
        }
        else if segue.identifier == "SampleInfoSegue" {
            let controller = segue.destination as! SampleInfoViewController
            controller.folderName = self.folderName
        }
    }
    
    //MARK: - Actions
    
    @IBAction func valueChanged(_ sender: UISegmentedControl) {
        self.infoContainerView.isHidden = (sender.selectedSegmentIndex == 1)
    }
    
}
