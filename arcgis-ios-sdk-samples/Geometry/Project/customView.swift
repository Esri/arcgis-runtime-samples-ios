//
//  CustomView.swift
//  ArcGIS Runtime SDK Samples
//
//  Created by Vivian Quach on 6/27/19.
//  Copyright © 2019 Esri. All rights reserved.
//

import Foundation
import UIKit
import ArcGIS

class customView: UIView {
    //initWithFrame to init view from code
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    //initWithCode to init view from xib or storyboard
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    //common func to init our view
    private func setupView() {
       
    }
}
