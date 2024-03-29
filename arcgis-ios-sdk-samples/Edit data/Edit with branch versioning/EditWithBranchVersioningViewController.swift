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
    // MARK: Storyboard views
    
    /// The label to display branch versioning status.
    @IBOutlet var statusLabel: UILabel!
    /// The button to create a version.
    @IBOutlet var createBarButtonItem: UIBarButtonItem!
    /// The button to switch to a version.
    @IBOutlet var switchBarButtonItem: UIBarButtonItem!
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISStreets)
            mapView.touchDelegate = self
            mapView.callout.delegate = self
        }
    }
    
    // MARK: Properties
    
    /// The geodatabase's default branch version name.
    var defaultVersionName = ""
    /// The geodatabase's existing version names.
    /// - Note: To get a full list of versions, use `AGSServiceGeodatabase.fetchVersions(completion:)`.
    ///         In this sample, only the default version and versions created in current session are shown.
    var existingVersionNames = [String]() {
        didSet {
            switchBarButtonItem.isEnabled = existingVersionNames.count > 1
        }
    }
    /// The name of the branch that the user is currently on.
    var currentVersionName = "" {
        willSet(newValue) {
            // When the service has internal error, it might give empty version name string.
            if !newValue.isEmpty {
                setStatus(message: newValue)
            }
        }
    }
    
    /// The service geodatabase to demo branch versioning.
    var serviceGeodatabase: AGSServiceGeodatabase!
    /// A feature layer to display damaged building features.
    var featureLayer: AGSFeatureLayer!
    /// A reference to current selected feature.
    var selectedFeature: AGSFeature?
    /// A reference to the cancelable identify layer operation.
    var identifyOperation: AGSCancelable?
    
    /// Possible values for the service's "typdamage" attribute.
    private enum DamageType: String, CaseIterable {
        case destroyed = "Destroyed"
        case major = "Major"
        case minor = "Minor"
        case affected = "Affected"
        case inaccessible = "Inaccessible"
        case `default` = "Default"
        
        /// The human readable name of the DamageType.
        var title: String {
            switch self {
            case .destroyed: return "Destroyed"
            case .major: return "Major"
            case .minor: return "Minor"
            case .affected: return "Affected"
            case .inaccessible: return "Inaccessible"
            case .`default`: return "Default"
            }
        }
    }
    
    // MARK: Methods
    
    /// Load and set a service geodatabase from a feature service URL.
    ///
    /// - Parameter serviceURL: The URL to the feature service.
    func loadServiceGeodatabase(from serviceURL: URL) {
        let serviceGeodatabase = AGSServiceGeodatabase(url: serviceURL)
        // NOTE: Never hardcode login information in a production application. This is done solely for the sake of the sample.
        serviceGeodatabase.credential = AGSCredential(user: "editor01", password: "S7#i2LWmYH75")
        UIApplication.shared.showProgressHUD(message: "Loading service geodatabase…")
        serviceGeodatabase.load { [weak self] error in
            UIApplication.shared.hideProgressHUD()
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
                self.setStatus(message: "Error loading service geodatabase.")
            } else {
                self.serviceGeodatabase = serviceGeodatabase
                // Load with default version.
                self.defaultVersionName = serviceGeodatabase.defaultVersionName
                self.existingVersionNames.append(serviceGeodatabase.defaultVersionName)
                
                // Load feature layer.
                self.loadFeatureLayer(with: serviceGeodatabase.table(withLayerID: 0)!) { [weak self] featureLayer in
                    // After the feature layer is loaded, switch to default version.
                    self?.switchVersion(to: serviceGeodatabase.defaultVersionName)
                    self?.featureLayer = featureLayer
                    // Add the feature layer to the map.
                    self?.mapView.map?.operationalLayers.add(featureLayer)
                }
            }
        }
    }
    
    /// Load a feature layer with a feature table.
    ///
    /// - Parameters:
    ///   - featureTable: The feature table for creating the feature layer.
    ///   - completion: A closure that pass back an `AGSFeatureLayer` object after it is successfully loaded.
    func loadFeatureLayer(with featureTable: AGSFeatureTable, completion: @escaping (AGSFeatureLayer) -> Void) {
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        UIApplication.shared.showProgressHUD(message: "Loading feature layer…")
        featureLayer.load { [weak self] error in
            UIApplication.shared.hideProgressHUD()
            if let extent = featureLayer.fullExtent {
                // Zoom to the target extent with animation.
                self?.mapView.setViewpoint(AGSViewpoint(targetExtent: extent), completion: nil)
                self?.createBarButtonItem.isEnabled = true
                completion(featureLayer)
            } else if let error = error {
                self?.presentAlert(error: error)
            }
        }
    }
    
    /// Identify a tapped point on a feature layer.
    ///
    /// - Parameters:
    ///   - featureLayer: The feature layer where to identify the features.
    ///   - screenPoint: The tapped screen point.
    ///   - completion: A closure to pass the identified feature for further usage.
    func identifyFeature(on featureLayer: AGSFeatureLayer, at screenPoint: CGPoint, completion: @escaping (AGSFeature) -> Void) {
        // Clear selection before identifying layers.
        clearSelection()
        // Clear in-progress identify operation.
        identifyOperation?.cancel()
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
    
    /// Make a new branch version with parameters in the service geodatabase.
    ///
    /// - Parameters:
    ///   - geodatabase: The geodatabase to create the version.
    ///   - parameters: The parameters for the new branch version.
    ///   - completion: The results for `AGSServiceGeodatabase.createVersion(with:completion:)` call.
    func makeVersion(geodatabase: AGSServiceGeodatabase, with parameters: AGSServiceVersionParameters, completion: @escaping (Result<String, Error>) -> Void) {
        geodatabase.createVersion(with: parameters) { serviceVersionInfo, error in
            if let info = serviceVersionInfo {
                // Create version succeeded.
                completion(.success(info.name))
            } else if let error = error {
                // Failed to create version.
                completion(.failure(error))
            }
        }
    }
    
    /// Switch the geodatabase to connect to a new branch version.
    ///
    /// - Parameter branchVersionName: The new branch version name to connect to.
    func switchVersion(to branchVersionName: String) {
        if currentVersionName == defaultVersionName {
            // Discard local edits if currently on default branch.
            // Since making edits on default branch is disabled,
            // code below won't get executed, but left here for parity.
            undoLocalEdits(geodatabase: serviceGeodatabase) { [weak self] in
                self?.serviceGeodatabase.switchVersion(withName: branchVersionName) { error in
                    guard let self = self else { return }
                    if let error = error {
                        self.presentAlert(error: error)
                    } else {
                        DispatchQueue.main.async { [weak self] in self?.currentVersionName = branchVersionName }
                    }
                }
            }
        } else {
            // Apply local edits when switching to a user created branch.
            applyLocalEdits(geodatabase: serviceGeodatabase) { [weak self] in
                self?.serviceGeodatabase.switchVersion(withName: branchVersionName) { error in
                    guard let self = self else { return }
                    if let error = error {
                        self.presentAlert(error: error)
                    } else {
                        DispatchQueue.main.async { [weak self] in self?.currentVersionName = branchVersionName }
                    }
                }
            }
        }
    }
    
    /// Apply local edits to the geodatabase.
    ///
    /// - Parameters:
    ///   - geodatabase: The geodatabase to apply edits.
    ///   - completion: A closure to execute after edits are applied.
    func applyLocalEdits(geodatabase: AGSServiceGeodatabase, completion: @escaping () -> Void) {
        if geodatabase.hasLocalEdits() {
            UIApplication.shared.showProgressHUD(message: "Applying local edits…")
            geodatabase.applyEdits { _, _ in
                UIApplication.shared.hideProgressHUD()
                completion()
            }
        } else {
            completion()
        }
    }
    
    /// Undo local edits on the geodatabase.
    ///
    /// - Parameters:
    ///   - geodatabase: The geodatabase to discard edits.
    ///   - completion: A closure to execute after edits are undone.
    func undoLocalEdits(geodatabase: AGSServiceGeodatabase, completion: @escaping () -> Void) {
        if geodatabase.hasLocalEdits() {
            UIApplication.shared.showProgressHUD(message: "Discarding local edits…")
            geodatabase.undoLocalEdits { _ in
                UIApplication.shared.hideProgressHUD()
                completion()
            }
        } else {
            completion()
        }
    }
    
    // MARK: Actions
    
    @IBAction func createBarButtonItemTapped(_ sender: UIBarButtonItem) {
        // Clear selection before creating a new branch version.
        clearSelection()
        mapView.callout.dismiss()
        chooseVersionAccessPermission(sender) { permission in
            self.askUserForBranchDetails(permission: permission) { [weak self] parameters in
                guard let self = self else { return }
                self.makeVersion(geodatabase: self.serviceGeodatabase, with: parameters) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let versionName):
                        self.existingVersionNames.append(versionName)
                        // Switch to the new version after it is created.
                        self.switchVersion(to: versionName)
                    case .failure(let error):
                        self.presentAlert(error: error)
                        self.setStatus(message: "Error creating new version.")
                    }
                }
            }
        }
    }
    
    @IBAction func switchBarButtonItemTapped(_ sender: UIBarButtonItem) {
        // Clear selection before switching to a new branch version.
        clearSelection()
        mapView.callout.dismiss()
        chooseVersion(sender) { versionName in
            self.switchVersion(to: versionName)
        }
    }
    
    // MARK: UI
    
    func clearSelection() {
        guard let feature = selectedFeature else { return }
        featureLayer.unselectFeature(feature)
        selectedFeature = nil
    }
    
    func setStatus(message: String) {
        statusLabel.text = message
    }
    
    func showCallout(for feature: AGSFeature, tapLocation: AGSPoint?, isAccessoryButtonHidden: Bool = false) {
        let placeName = feature.attributes["placename"] as? String
        let damageName = feature.attributes["typdamage"] as? String ?? "Default"
        mapView.callout.title = damageName
        mapView.callout.detail = placeName
        mapView.callout.isAccessoryButtonHidden = isAccessoryButtonHidden
        mapView.callout.show(for: feature, tapLocation: tapLocation, animated: true)
    }
    
    /// Move the currently selected feature to the given map point, by updating the selected feature's geometry and feature table.
    func moveFeature(_ feature: AGSFeature, to mapPoint: AGSPoint) {
        // Create an alert to confirm that the user wants to update the geometry.
        let alert = UIAlertController(
            title: "Confirm Move",
            message: "Do you want to move the selected feature?",
            preferredStyle: .alert
        )
        // Clear the selection and selected feature on cancel.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.clearSelection()
        }
        // Move the feature to a new point geometry.
        let moveAction = UIAlertAction(title: "Move", style: .default) { _ in
            // Set the selected feature's geometry to the new map point.
            feature.geometry = mapPoint
            // Update the selected feature's feature table.
            feature.featureTable?.update(feature) { [weak self] _ in
                self?.clearSelection()
            }
        }
        alert.addAction(cancelAction)
        alert.addAction(moveAction)
        alert.preferredAction = moveAction
        present(alert, animated: true)
    }
    
    func askUserForBranchDetails(permission: AGSVersionAccess, completion: @escaping (AGSServiceVersionParameters) -> Void) {
        // Create an object to observe changes from the text fields.
        var textFieldObserver: NSObjectProtocol!
        // An alert to get user input for branch name and description.
        let alertController = UIAlertController(
            title: "Create Branch Version",
            message: "Please provide a branch name and a description.",
            preferredStyle: .alert
        )
        // Remove observer on cancel.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            NotificationCenter.default.removeObserver(textFieldObserver!)
        }
        // Create a new version and remove observer.
        let createAction = UIAlertAction(title: "Create", style: .default) { _ in
            NotificationCenter.default.removeObserver(textFieldObserver!)
            let branchText = alertController.textFields![0].text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let descriptionText = alertController.textFields![1].text?.trimmingCharacters(in: .whitespacesAndNewlines)
            // Make service parameters with provided information.
            let parameters = AGSServiceVersionParameters()
            parameters.access = permission
            parameters.name = branchText
            if let description = descriptionText {
                parameters.parametersDescription = description
            }
            completion(parameters)
        }
        createAction.isEnabled = false
        alertController.addAction(cancelAction)
        alertController.addAction(createAction)
        alertController.preferredAction = createAction
        
        // The text field for version name.
        alertController.addTextField { textField in
            textField.placeholder = "Version name must be unique"
            textField.delegate = self
            textFieldObserver = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: .main
            ) { [ unowned createAction ] _ in
                let text = textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                // Enable the done button if branch version textfield is not empty.
                createAction.isEnabled = !text.isEmpty
            }
        }
        // The text field for version description.
        alertController.addTextField { textField in
            textField.placeholder = "Branch version description here"
        }
        present(alertController, animated: true)
    }
    
    func editFeatureDamageAttribute(feature: AGSFeature) {
        let alertController = UIAlertController(
            title: "Damage Type",
            message: "Choose a damage type for the building.",
            preferredStyle: .actionSheet
        )
        DamageType.allCases.forEach { type in
            let action = UIAlertAction(title: type.title, style: .default) { _ in
                feature.attributes["typdamage"] = type.rawValue
                feature.featureTable?.update(feature)
                self.mapView.callout.dismiss()
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.mapView.callout.dismiss()
        }
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.sourceView = mapView
        let point = feature.geometry?.extent.center
        let sourcePoint = mapView.location(toScreen: point!)
        let sourceRect = CGRect(origin: sourcePoint, size: .zero)
        alertController.popoverPresentationController?.sourceRect = sourceRect
        present(alertController, animated: true)
    }
    
    func chooseVersion(_ sender: UIBarButtonItem, completion: @escaping (String) -> Void) {
        let alertController = UIAlertController(
            title: "Versions",
            message: "Choose to switch to another version.",
            preferredStyle: .actionSheet
        )
        existingVersionNames.forEach { name in
            let action = UIAlertAction(title: name, style: .default) { _ in
                completion(name)
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = sender
        present(alertController, animated: true)
    }
    
    func chooseVersionAccessPermission(_ sender: UIBarButtonItem, completion: @escaping (AGSVersionAccess) -> Void) {
        let alertController = UIAlertController(
            title: "Access Permissions",
            message: "Choose an access level for the new branch version.",
            preferredStyle: .actionSheet
        )
        let versionAccessPermission: [AGSVersionAccess] = [.public, .protected, .private]
        versionAccessPermission.forEach { versionAccess in
            let action = UIAlertAction(title: versionAccess.title, style: .default) { _ in
                completion(versionAccess)
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
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["EditWithBranchVersioningViewController"]
        // Load the service geodatabase.
        let damageFeatureService = URL(string: "https://sampleserver7.arcgisonline.com/server/rest/services/DamageAssessment/FeatureServer")!
        loadServiceGeodatabase(from: damageFeatureService)
    }
}

// MARK: - AGSGeoViewTouchDelegate

extension EditWithBranchVersioningViewController: AGSGeoViewTouchDelegate {
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // Dismiss any presenting callout.
        mapView.callout.dismiss()
        // Disable features editing on the default branch and only allow showing callout.
        if currentVersionName == defaultVersionName {
            // Tap to identify a pixel on the feature layer.
            identifyFeature(on: featureLayer, at: screenPoint) { [weak self] feature in
                // Show a callout without the accessory button.
                self?.showCallout(for: feature, tapLocation: mapPoint, isAccessoryButtonHidden: true)
            }
        } else {
            if let selectedFeature = selectedFeature {
                // If there is a feature selected already, tap elsewhere to move it.
                moveFeature(selectedFeature, to: mapPoint)
            } else {
                // Tap to identify a pixel on the feature layer.
                identifyFeature(on: featureLayer, at: screenPoint) { [weak self] feature in
                    self?.showCallout(for: feature, tapLocation: mapPoint)
                }
            }
        }
    }
}

// MARK: - AGSCalloutDelegate

extension EditWithBranchVersioningViewController: AGSCalloutDelegate {
    func didTapAccessoryButton(for callout: AGSCallout) {
        // Dismiss the callout.
        callout.dismiss()
        // Show editing options actionsheet.
        editFeatureDamageAttribute(feature: selectedFeature!)
    }
}

// MARK: - UITextFieldDelegate

extension EditWithBranchVersioningViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        // 1. Must not include special characters: . ; ' "
        let invalidCharacters = ".;'\""
        let noInvalidCharacters = CharacterSet(charactersIn: invalidCharacters).isDisjoint(with: CharacterSet(charactersIn: text))
        // 2. Branch version string does not exceed 62 characters.
        let noLongerThan62Characters = text.count <= 62
        return noInvalidCharacters && noLongerThan62Characters
    }
}

private extension AGSVersionAccess {
    /// The human readable name of the version access.
    var title: String {
        switch self {
        case .public: return "Public"
        case .protected: return "Protected"
        case .private: return "Private"
        @unknown default: return "Unknown"
        }
    }
}
