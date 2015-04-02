//
// Copyright 2015 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

import UIKit

let LEVEL_INDENT:CGFloat = 15

class CheckBox:UIButton {
    
    var isChecked:Bool = false {
        didSet {
            self.updateCheckBox()
        }
    }
    
    func changeCheckBox() {
        self.isChecked = !self.isChecked
    }
    
    func updateCheckBox() {
        if self.isChecked {
            self.setImage(UIImage(named: "checkbox_checked.png"), forState:.Normal)
        } else {
            self.setImage(UIImage(named: "checkbox_unchecked.png"), forState:.Normal)
        }
    }
}

protocol LayerInfoCellDelegate:class {
    func layerInfoCell(layerInfoCell:LayerInfoCell, didChangeVisibility visibility:Bool)
}

class LayerInfoCell: UITableViewCell {
    
    @IBOutlet weak var valueLabel:UILabel!
    @IBOutlet weak var visibilitySwitch:CheckBox!
    @IBOutlet weak var arrowImage:UIImageView!
    
    @IBOutlet weak var arrowImageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var visibilitySwitchLeadingConstraint: NSLayoutConstraint!
    
    
    var level:Int!
    var expanded:Bool = false {
        //update the arrow image based on the state of the expansion
        didSet {
            if self.arrowImage != nil {
                self.arrowImage.image = UIImage(named: self.expanded ? "CircleArrowDown_sml" : "CircleArrowRight_sml")
            }
        }
    }
    var canChangeVisibility:Bool = false {
        //show checkbox if the layer can be hidden
        didSet {
            canChangeVisibility ? self.showVisibilitySwitch() : hideVisibilitySwitch()
        }
    }
    var visibility:Bool = false {
        //set the state of the checkbox
        didSet {
            self.visibilitySwitch?.isChecked = visibility
        }
    }
    
    weak var layerInfoCellDelegate:LayerInfoCellDelegate?
    
    //called when the user checks or unchecks the visibility switch
    @IBAction func visibilityChanged() {
        self.visibilitySwitch.changeCheckBox()
        self.layerInfoCellDelegate?.layerInfoCell(self, didChangeVisibility: self.visibilitySwitch.isChecked)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //set the indentation based on the level
        self.arrowImageLeadingConstraint.constant = CGFloat(self.level + 1) * LEVEL_INDENT
    }
    
    //MARK: - hide/show switch
    
    func hideVisibilitySwitch() {
        self.visibilitySwitch.hidden = true
        self.visibilitySwitchLeadingConstraint.constant = -self.visibilitySwitch.bounds.size.width
    }
    
    func showVisibilitySwitch() {
        self.visibilitySwitch.hidden = false
        self.visibilitySwitchLeadingConstraint.constant = 8
    }
}
