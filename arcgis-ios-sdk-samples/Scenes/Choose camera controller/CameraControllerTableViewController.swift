//
//  CameraControllerTableViewController.swift
//  ArcGIS Runtime SDK Samples
//
//  Created by Garima Dhakal on 4/8/19.
//  Copyright © 2019 Esri. All rights reserved.
//

import UIKit
import ArcGIS

protocol CameraControllerTableViewControllerDelagate: AnyObject {
    func selectedCamera(type: AGSCameraController)
}

class CameraControllerTableViewController: UITableViewController {
    weak var cameraControllerDelegate: CameraControllerTableViewControllerDelagate!
    var cameraControllers = [AGSCameraController]()
    var selectedRow: Int?
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cameraControllers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = getDescription(of: cameraControllers[indexPath.row])
        
        if let selectedRow = selectedRow, indexPath.row == selectedRow {
            tableView.selectRow(at: IndexPath(row: selectedRow, section: 0), animated: false, scrollPosition: .none)
            tableView.delegate?.tableView!(tableView, didSelectRowAt: indexPath)
        }
        
        return cell
    }
    
    /// Gets description for a specified camera controller.
    ///
    /// - Parameter cameraController: Camera controller of scene view.
    /// - Returns: A text description of the camera controller.
    func getDescription(of cameraController: AGSCameraController) -> String {
        if cameraController is AGSOrbitGeoElementCameraController {
            return "Orbit camera around plane"
        } else if cameraController is AGSOrbitLocationCameraController {
            return "Orbit camera around crater"
        } else {
            return "Free pan round the globe"
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        cameraControllerDelegate.selectedCamera(type: cameraControllers[indexPath.row])
    }
}
