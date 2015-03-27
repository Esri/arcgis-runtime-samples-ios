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

class LayerLegendCell: UITableViewCell {

    @IBOutlet weak var legendImageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var legendImage:UIImageView!
    @IBOutlet weak var legendLabel:UILabel!
    var level:Int!

    override func layoutSubviews() {
        super.layoutSubviews()
        
        //indent the content based on the level
        self.legendImageLeadingConstraint.constant = CGFloat(self.level + 1) * LEVEL_INDENT
    }
}
