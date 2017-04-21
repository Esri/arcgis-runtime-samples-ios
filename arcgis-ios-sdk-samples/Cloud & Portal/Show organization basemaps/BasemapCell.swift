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
import ArcGIS

class BasemapCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var label: UILabel!
    
    var portalItem:AGSPortalItem! {
        didSet {
            
            //set portal item's title as the cell's label
            self.label.text = portalItem.title
            
            //portal item's thumbnail as the image on cell
            if let image = portalItem.thumbnail?.image {
                self.imageView.image = image
            }
            else {
                self.imageView.image = nil
                
                //if the thumbnail is not already downloaded
                portalItem.thumbnail?.load { [weak self] (error: Error?) in
                    if let error = error {
                        print(error)
                    }
                    else {
                        self?.imageView.image = self?.portalItem.thumbnail?.image
                    }
                }
            }
        }
    }
}
