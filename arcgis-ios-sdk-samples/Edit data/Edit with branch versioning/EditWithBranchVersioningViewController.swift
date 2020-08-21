// Copyright 2020 Esri
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

class EditWithBranchVersioningViewController: UIViewController {
    /// The label to display branch versioning status.
    @IBOutlet var statusLabel: UILabel!
    
    @IBOutlet var versionBarButtonItem: UIBarButtonItem! {
        didSet {
            versionBarButtonItem.possibleTitles = ["Create version", "Switch version"]
        }
    }
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = makeMap()
            mapView.touchDelegate = self
            mapView.callout.delegate = self
        }
    }
    /// The geodatabase's default branch version name.
    var defaultVersionName: String!
    /// The geodatabase's newly created branch version name designated by the user.
    var createdVersionName: String!
    /// The name of the branch that the user is currently on.
    var currentVersionName: String! {
        didSet(newValue) {
            setStatus(message: newValue)
        }
    }
    
    var serviceGeodatabase: AGSServiceGeodatabase!
    var featureLayer: AGSFeatureLayer!
    var selectedFeature: AGSFeature!
    var identifyOperation: AGSCancelable?
    
    private enum DamageType: String, CaseIterable {
        case destroyed = "Destroyed"
        case major = "Major"
        case minor = "Minor"
        case affected = "Affected"
        case inaccessible = "Inaccessible"
    }
    
    /// Create a map.
    ///
    /// - Returns: An `AGSMap` object.
    func makeMap() -> AGSMap {
        let map = AGSMap(basemap: .streetsVector())
        let serviceGeodatabase = AGSServiceGeodatabase(url: URL(string: "https://sampleserver7.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer")!)
        serviceGeodatabase.credential = AGSCredential(user: "editor01", password: "editor01.password")
        serviceGeodatabase.load { [weak self] error in
            guard let self = self else { return }
            if serviceGeodatabase.loadStatus == .loaded {
                let serviceFeatureTable = serviceGeodatabase.table(withLayerID: 0)!
                let featureLayer = AGSFeatureLayer(featureTable: serviceFeatureTable)
                self.featureLayer = featureLayer
                map.operationalLayers.add(featureLayer)
                if let extent = featureLayer.fullExtent {
                    self.mapView.setViewpoint(AGSViewpoint(targetExtent: extent))
                }
                self.defaultVersionName = serviceGeodatabase.defaultVersionName
                self.currentVersionName = serviceGeodatabase.versionName
                if serviceGeodatabase.defaultVersionName != serviceGeodatabase.versionName {
                    self.versionBarButtonItem.title = "Switch version"
                }
                self.versionBarButtonItem.isEnabled = true
            } else if let error = error {
                self.presentAlert(error: error)
            }
        }
        self.serviceGeodatabase = serviceGeodatabase
        return map
    }
    
    func identifyPixel(at screenPoint: CGPoint, completion: @escaping (AGSFeature) -> Void) {
        // Clear selection before identify.
        if let selectedFeature = selectedFeature {
            self.featureLayer.unselectFeature(selectedFeature)
        }
        // Clear in-progress identify operation.
        identifyOperation?.cancel()
        identifyOperation = nil
        // Identify the tapped feature.
        identifyOperation = mapView.identifyLayer(featureLayer, screenPoint: screenPoint, tolerance: 10.0, returnPopupsOnly: false) { [weak self] identifyResult in
            guard let self = self else { return }
            guard !identifyResult.geoElements.isEmpty, let firstFeature = identifyResult.geoElements.first as? AGSFeature else {
                return
            }
            self.featureLayer.select(firstFeature)
            self.selectedFeature = firstFeature
            completion(firstFeature)
        }
    }
    
    func editFeatureAttribute(feature: AGSFeature, sourceRect: CGRect) {
        let alertController = UIAlertController(
            title: "Damage type",
            message: "Choose a damage type for the building.",
            preferredStyle: .actionSheet
        )
        DamageType.allCases.forEach { type in
            let action = UIAlertAction(title: type.rawValue, style: .default) { _ in
                feature.attributes["typdamage"] = type.rawValue
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.sourceRect = sourceRect
        present(alertController, animated: true)
    }
    
    @IBAction func versionBarButtonItemTapped(_ sender: UIBarButtonItem) {
        if sender.title == "Create version" {
            chooseVersionAccessPermission(sender) { permission in
                self.createBranchAlert(permission: permission) { [weak self] result in
                    switch result {
                    case .success(let versionName):
                        sender.title = "Switch version"
                        self?.createdVersionName = versionName
                    case .failure(let error):
                        self?.presentAlert(error: error)
                    }
                }
            }
        } else {
            let otherVersion = currentVersionName == defaultVersionName ? createdVersionName : defaultVersionName
            switchVersion(to: otherVersion!)
        }
    }
    
    func createServiceParameters(uniqueName: String, description: String?, accessPermission: AGSVersionAccess) -> AGSServiceVersionParameters {
        let parameters = AGSServiceVersionParameters()
        parameters.name = uniqueName
        parameters.access = accessPermission
        if let description = description {
            parameters.parametersDescription = description
        }
        return parameters
    }
    
    func createVersion(parameters: AGSServiceVersionParameters, completion: @escaping (Result<String, Error>) -> Void) {
//        serviceGeodatabase.fetchVersions { [weak self] serviceVersionInfo, error in
//            if let info = serviceVersionInfo {
//                let versionNames = info.map { $0.name }
//
//            } else if let error = error {
//                self?.presentAlert(error: error)
//            }
//        }
        serviceGeodatabase.createVersion(with: parameters) { serviceVersionInfo, error in
            if let info = serviceVersionInfo {
                // Create version succeeded.
                completion(.success(info.name))
            } else if let error = error {
                // Failed to create version.
                completion(.failure(error))
            }
        }
    }
    
    func switchVersion(to branchVersionName: String) {
        serviceGeodatabase.switchVersion(withName: branchVersionName) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else {
                self.currentVersionName = branchVersionName
                // Reload feature table with the new version.
                self.featureLayer.featureTable?.load()
            }
        }
    }
    
    func applyLocalEdits(completion: @escaping () -> Void) {
        if serviceGeodatabase.hasLocalEdits() {
            serviceGeodatabase.applyEdits { _, error in
                if let error = error {
                    self.presentAlert(error: error)
                } else {
                    completion()
                }
            }
        } else {
            completion()
        }
    }
    
    func undoLocalEdits() {
        if serviceGeodatabase.hasLocalEdits() {
            serviceGeodatabase.undoLocalEdits { error in
                if let error = error {
                    self.presentAlert(error: error)
                }
            }
        }
    }
    
    // MARK: UI
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    func showCallout(_ feature: AGSFeature, tapLocation: AGSPoint?) {
        mapView.callout.title = feature.attributes["typdamage"] as? String
        mapView.callout.show(for: feature, tapLocation: tapLocation, animated: true)
    }
    
    func createBranchAlert(permission: AGSVersionAccess, completion: @escaping (Result<String, Error>) -> Void) {
        // Create an object to observe changes from the text fields.
        var textFieldObserver: NSObjectProtocol!
        // An alert to get user input for branch name and description.
        let alertController = UIAlertController(
            title: "Create branch version",
            message: "Please provide a branch name and an optional description.",
            preferredStyle: .alert
        )
        // Remove observer on cancel.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            NotificationCenter.default.removeObserver(textFieldObserver!)
        }
        // Create a new version and remove observer.
        let createAction = UIAlertAction(title: "Create", style: .default) { [weak self] _ in
            guard let self = self else { return }
            NotificationCenter.default.removeObserver(textFieldObserver!)
            let branchTextField = alertController.textFields![0]
            let descriptionTextField = alertController.textFields![1]
            // If the text field is empty, do nothing.
            guard let branchText = branchTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !branchText.isEmpty else { return }
            let descriptionText = descriptionTextField.text
            let parameters = self.createServiceParameters(uniqueName: branchText, description: descriptionText, accessPermission: permission)
            self.createVersion(parameters: parameters) { result in
                completion(result)
            }
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(createAction)
        alertController.preferredAction = createAction
        
        // The text field for version name.
        alertController.addTextField { textField in
            textField.placeholder = "Must be unique, no leading space, cannot include . ; ' \""
            textFieldObserver = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: .main
            ) { _ in
                let text = alertController.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines)
                // Enable the done button if
                // 1. branch version textfield is not empty.
                let notEmpty = text?.isEmpty == false
                // 2. branch version string does not exceed 62 characters.
                let noLongerThan62Characters = text?.count ?? 0 <= 62
                createAction.isEnabled = notEmpty && noLongerThan62Characters
            }
        }
        // The text field for version description.
        alertController.addTextField { textField in
            textField.placeholder = "Enter your branch version description"
        }
        present(alertController, animated: true)
    }
    
    func chooseVersionAccessPermission(_ sender: UIBarButtonItem, completion: @escaping (AGSVersionAccess) -> Void) {
        let alertController = UIAlertController(
            title: "Branch version access level",
            message: "Choose an access level for the new branch version.",
            preferredStyle: .actionSheet
        )
        let versionAccessPermission: KeyValuePairs<String, AGSVersionAccess> = [
            "Public": .public,
            "Protected": .protected,
            "Private": .private,
        ]
        versionAccessPermission.forEach { name, permission in
            let action = UIAlertAction(title: name, style: .default) { _ in
                completion(permission)
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = sender
        present(alertController, animated: true)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames  = ["EditWithBranchVersioningViewController"]
    }
}

extension EditWithBranchVersioningViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Dismiss presenting callout, if any.
        mapView.callout.dismiss()
        // Tap to identify a pixel on the feature layer.
        identifyPixel(at: screenPoint) { feature in
            self.showCallout(feature, tapLocation: mapPoint)
        }
    }
}

// MARK: - AGSCalloutDelegate

extension EditWithBranchVersioningViewController: AGSCalloutDelegate {
    func didTapAccessoryButton(for callout: AGSCallout) {
        // Hide the callout
        // mapView.callout.dismiss()
        // Show editing options table.
        editFeatureAttribute(feature: selectedFeature, sourceRect: callout.bounds)
    }
}

// MARK: - UITextFieldDelegate

extension EditWithBranchVersioningViewController: UITextFieldDelegate {
    // Ensure that the text field will only accept numbers.
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        // Must not include special characters: . ; ' "
        let invalidCharacters = ".;'\""
        return CharacterSet(charactersIn: invalidCharacters).isDisjoint(with: CharacterSet(charactersIn: text))
    }
}
