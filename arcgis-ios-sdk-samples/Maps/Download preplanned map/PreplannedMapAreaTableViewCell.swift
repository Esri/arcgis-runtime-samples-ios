//
//  PreplannedMapAreaTableViewCell.swift
//  ArcGIS Runtime SDK Samples
//
//  Created by Steven Baranski on 8/16/19.
//  Copyright © 2019 Esri. All rights reserved.
//

import UIKit

// MARK: - Constants

private enum Constants {
    static let progressTintColor = UIColor.primaryBlue
    static let trackTintColor = UIColor.backgroundGray
}

// MARK: - PreplannedMapAreaTableViewCell

class PreplannedMapAreaTableViewCell: UITableViewCell {
    @IBOutlet private(set) weak var progressView: UIProgressView!

    override func awakeFromNib() {
        super.awakeFromNib()

        progressView.progressTintColor = Constants.progressTintColor
        progressView.trackTintColor = Constants.trackTintColor
    }
}
