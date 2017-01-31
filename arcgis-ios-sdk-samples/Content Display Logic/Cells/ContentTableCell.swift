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

class ContentTableCell: UITableViewCell {

    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var detailLabel:UILabel!
    @IBOutlet var infoButton:UIButton!
    @IBOutlet var parentView:UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        parentView.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        parentView.layer.borderWidth = 1
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        
        if highlighted {
            self.parentView.backgroundColor = UIColor.secondaryBlue()
            self.titleLabel.textColor = UIColor.white
            self.detailLabel.textColor = UIColor.white
            self.infoButton.tintColor = UIColor.white
        }
        else {
            self.parentView.backgroundColor = UIColor.white
            self.titleLabel.textColor = UIColor.primaryTextColor()
            self.detailLabel.textColor = UIColor.secondaryTextColor()
            self.infoButton.tintColor = UIColor.secondaryBlue()
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        
        if selected {
            self.parentView.backgroundColor = UIColor.secondaryBlue()
            self.titleLabel.textColor = UIColor.white
            self.detailLabel.textColor = UIColor.white
            self.infoButton.tintColor = UIColor.white
        }
        else {
            self.parentView.backgroundColor = UIColor.white
            self.titleLabel.textColor = UIColor.primaryTextColor()
            self.detailLabel.textColor = UIColor.secondaryTextColor()
            self.infoButton.tintColor = UIColor.secondaryBlue()
        }
    }
}
