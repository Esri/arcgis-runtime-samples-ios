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
import ArcGIS

class GroupUserCell: UITableViewCell {

    @IBOutlet private var thumbnailImageView: UIImageView!
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var descriptionLabel: UILabel!
    
    var portalUser:AGSPortalUser! {
        didSet {
            
            self.titleLabel.text = portalUser.fullName
            self.descriptionLabel.text = portalUser.userDescription
            self.thumbnailImageView.layer.cornerRadius = 40
            self.thumbnailImageView.layer.masksToBounds = true
            
            self.thumbnailImageView.image = UIImage(named: "Placeholder")
            
            
            if let thumbnail = portalUser.thumbnail {
                if thumbnail.image != nil {
                    self.thumbnailImageView.image = thumbnail.image
                }
                else {
                    thumbnail.load { [weak self] (error: Error?) in
                        if error == nil {
                            self?.thumbnailImageView.image = thumbnail.image
                        }
                    }
                }
            }
        }
    }
}
