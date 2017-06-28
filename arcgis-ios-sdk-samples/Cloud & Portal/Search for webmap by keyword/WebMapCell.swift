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
//

import UIKit
import ArcGIS

class WebMapCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel:UILabel!
    @IBOutlet weak var thumbnail:UIImageView!
    @IBOutlet weak var timerLabel:UILabel!
    @IBOutlet weak var ownerLabel:UILabel!
    
    var portalItem:AGSPortalItem! {
        didSet {
            
            if portalItem != nil {
                self.titleLabel.text = portalItem.title
                self.ownerLabel.text = portalItem.owner
                
                //imageview border
                self.thumbnail.layer.borderColor = UIColor.darkGray.cgColor
                self.thumbnail.layer.borderWidth = 1
                
                //time label
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                self.timerLabel.text = dateFormatter.string(from: portalItem.modified!)
                
                self.thumbnail.image = UIImage(named: "Placeholder")
                
                portalItem.thumbnail?.load(completion: { [weak self] (error: Error?) -> Void in
                    if let error = error {
                        print("Error downloading thumbnail :: \(error.localizedDescription)")
                    }
                    else {
                        if let image = self?.portalItem.thumbnail?.image {
                            self?.thumbnail.image = image
                        }
                    }
                })
            }
        }
    }
}
