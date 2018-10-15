//
//  UIViewController.swift
//  arcgis-ios-sdk-samples
//
//  Created by Quincy Morgan on 10/15/18.
//  Copyright © 2018 Esri. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func presentAlert(title: String? = nil, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        alertController.preferredAction = okAction
        present(alertController, animated: true)
    }
    
    func presentAlert(error: Error) {
        presentAlert(title: "Error", message: error.localizedDescription)
    }
    
}
