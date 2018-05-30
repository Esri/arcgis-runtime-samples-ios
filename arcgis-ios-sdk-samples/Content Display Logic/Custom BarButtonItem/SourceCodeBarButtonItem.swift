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

class SourceCodeBarButtonItem: UIBarButtonItem {
   
    var filenames:[String]!
    weak var navController:UINavigationController?
    var folderName:String!
    
    override init() {
        super.init()
        self.image = UIImage(named: "InfoIcon")
        self.target = self
        self.action = #selector(SourceCodeBarButtonItem.showSegmentedVC)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func showSegmentedVC() {
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storyboard.instantiateViewController(withIdentifier: "SegmentedViewController") as! SegmentedViewController
        controller.filenames = filenames
        controller.folderName = self.folderName
        self.navController?.show(controller, sender: self)
    }
    
    
}
