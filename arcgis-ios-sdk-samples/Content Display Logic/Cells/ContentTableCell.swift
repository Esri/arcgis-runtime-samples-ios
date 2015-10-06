//
//  ContentTableCell.swift
//  arcgis-ios-sdk-samples
//
//  Created by Gagandeep Singh on 9/30/15.
//  Copyright © 2015 Esri. All rights reserved.
//

import UIKit

class ContentTableCell: UITableViewCell {

    @IBOutlet var titleLabel:UILabel!
    @IBOutlet var detailLabel:UILabel!
    @IBOutlet var infoButton:UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
