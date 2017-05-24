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

class PlaneStatsViewController: UIViewController {
    
    @IBOutlet var altitudeLabel:UILabel!
    @IBOutlet var headingLabel:UILabel!
    @IBOutlet var pitchLabel:UILabel!
    @IBOutlet var rollLabel:UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //preferred content size
        self.preferredContentSize = CGSize(width: 220, height: 200)
    }
}
