//
//  CategoryCell.swift
//  arcgis-ios-sdk-samples
//
//  Created by Gagandeep Singh on 10/17/16.
//  Copyright © 2016 Esri. All rights reserved.
//

import UIKit

class CategoryCell: UICollectionViewCell {
    
    @IBOutlet var backgroundImageView: UIImageView!
    @IBOutlet var iconBackgroundView: UIView!
    @IBOutlet var iconImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.iconBackgroundView.layer.cornerRadius = 25
        self.iconBackgroundView.layer.masksToBounds = true
    }
}
