//
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

class AppInfoViewController: UIViewController {

    @IBOutlet var appNameLabel:UILabel!
    @IBOutlet var appVersionLabel:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
        
        self.appNameLabel.text = appName
        self.appVersionLabel.text = "Built with ArcGIS Runtime SDK for iOS \(versionNumber!) (\(buildNumber!))"
        
        self.preferredContentSize = CGSize(width: 350, height: 350)
    }
    
    //MARK: - Actions
    
    @IBAction func closeAction() {
        self.dismiss(animated: true, completion: nil)
    }

}
