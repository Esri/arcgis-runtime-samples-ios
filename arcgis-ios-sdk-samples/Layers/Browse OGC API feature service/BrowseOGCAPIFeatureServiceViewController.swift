// Copyright 2021 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit
import ArcGIS

class BrowseOGCAPIFeatureServiceViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            mapView.map = AGSMap(basemapStyle: .arcGISTopographic)
            // Set the viewpoint to Daraa, Syria.
            mapView.setViewpoint(AGSViewpoint(latitude: 32.62, longitude: 36.10, scale: 20_000))
        }
    }
    /// The bar button to browse feature layers.
    @IBOutlet var layersBarButtonItem: UIBarButtonItem!
    
    // MARK: Properties
    
    /// The most recent query job.
    var lastQuery: AGSCancelable?
    /// The Daraa, Syria OGC API feature service URL.
    let defaultServiceURL = URL(string: "https://demo.ldproxy.net/daraa")!
    /// The service metadata of feature collections from the loaded service.
    var featureCollectionInfos: [AGSOGCFeatureCollectionInfo] = []
    /// The OGC feature collection info selected by the user.
    var selectedInfo: AGSOGCFeatureCollectionInfo?
    /// The OGC API features service.
    var service: AGSOGCFeatureService!
    /// A flag to indicate whether the service URL has been provided.
    var urlProvided = false
    
    /// The query parameters to populate features from the OGC API service.
    let queryParameters: AGSQueryParameters = {
        let queryParameters = AGSQueryParameters()
        // Set a limit of 1000 on the number of returned features per request,
        // because the default on some services could be as low as 10.
        queryParameters.maxFeatures = 1_000
        return queryParameters
    }()
    
    // MARK: Methods
    
    /// Create and load the OGC API features service from a URL.
    func loadService(url: URL) {
        service = AGSOGCFeatureService(url: url)
        service.load { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.presentAlert(error: error)
            } else if let infos = self.service.serviceInfo?.featureCollectionInfos {
                self.featureCollectionInfos = infos
                self.layersBarButtonItem.isEnabled = true
            }
        }
    }
    
    /// Load and display a feature layer from the OGC feature collection table.
    /// - Parameter table: The `AGSOGCFeatureCollectionTable` selected by user.
    func displayLayer(with table: AGSOGCFeatureCollectionTable) {
        // Cancel if there is an existing query request.
        lastQuery?.cancel()
        
        // Set the feature request mode to manual (only manual is currently
        // supported). In this mode, you must manually populate the table -
        // panning and zooming won't request features automatically.
        table.featureRequestMode = .manualCache
        
        lastQuery = table.populateFromService(
            with: queryParameters,
            clearCache: false,
            outfields: nil
        ) { [weak self, table] _, error in
            guard let self = self else { return }
            self.lastQuery = nil
            if let error = error,
               // Do not display error if user simply cancelled the request.
               (error as NSError).code != NSUserCancelledError {
                self.presentAlert(error: error)
            } else if let info = table.featureCollectionInfo,
                      let extent = info.extent {
                // Zoom to the extent of the selected collection.
                let featureLayer = AGSFeatureLayer(featureTable: table)
                featureLayer.renderer = self.makeRenderer(for: table.geometryType)
                self.mapView.map?.operationalLayers.setArray([featureLayer])
                self.mapView.setViewpointGeometry(extent, padding: 50)
                self.selectedInfo = info
            }
        }
    }
    
    /// Create an appropriate renderer for a type of geometry.
    func makeRenderer(for geometryType: AGSGeometryType) -> AGSSimpleRenderer? {
        let renderer: AGSSimpleRenderer?
        switch geometryType {
        case .point, .multipoint:
            renderer = AGSSimpleRenderer(symbol: AGSSimpleMarkerSymbol(style: .circle, color: .blue, size: 5))
        case .polyline:
            renderer = AGSSimpleRenderer(symbol: AGSSimpleLineSymbol(style: .solid, color: .blue, width: 1))
        case .polygon, .envelope:
            renderer = AGSSimpleRenderer(symbol: AGSSimpleFillSymbol(style: .solid, color: .blue, outline: nil))
        case .unknown:
            fallthrough
        @unknown default:
            renderer = nil
        }
        return renderer
    }
    
    // MARK: Action
    
    func askUserForServiceURL(completion: @escaping (Result<URL, Error>) -> Void) {
        // Create an object to observe changes from the text fields.
        var textFieldObserver: NSObjectProtocol!
        let alertController = UIAlertController(
            title: "Load OGC API feature service",
            message: "Please provide a URL to an OGC API feature service.",
            preferredStyle: .alert
        )
        // Remove observer on cancel.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            NotificationCenter.default.removeObserver(textFieldObserver!)
            completion(.failure(InputError.userCancelled))
        }
        // Validate and create URL from user input and remove observer.
        let loadAction = UIAlertAction(title: "Load", style: .default) { _ in
            NotificationCenter.default.removeObserver(textFieldObserver!)
            if let text = alertController.textFields![0].text,
               let serviceURL = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                completion(.success(serviceURL))
            } else {
                completion(.failure(InputError.invalidURL))
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(loadAction)
        alertController.preferredAction = loadAction
        
        // The text field for OGC API service URL.
        alertController.addTextField { [self] textField in
            textField.placeholder = defaultServiceURL.absoluteString
            textField.text = defaultServiceURL.absoluteString
            textField.keyboardType = .URL
            textFieldObserver = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: .main
            ) { [unowned loadAction] _ in
                let text = textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                // Enable the load button if textfield is not empty.
                loadAction.isEnabled = !text.isEmpty
            }
        }
        present(alertController, animated: true)
    }
    
    @IBAction func browseLayerInfos(_ sender: UIBarButtonItem) {
        let selectedIndex = featureCollectionInfos.firstIndex { $0 == selectedInfo }
        let optionsViewController = OptionsTableViewController(labels: featureCollectionInfos.map(\.title), selectedIndex: selectedIndex) { [self] newIndex in
            let selectedInfo = featureCollectionInfos[newIndex]
            let table = AGSOGCFeatureCollectionTable(featureCollectionInfo: selectedInfo)
            displayLayer(with: table)
        }
        optionsViewController.modalPresentationStyle = .popover
        optionsViewController.preferredContentSize = CGSize(width: 300, height: 300)
        optionsViewController.presentationController?.delegate = self
        optionsViewController.popoverPresentationController?.barButtonItem = sender
        present(optionsViewController, animated: true)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["BrowseOGCAPIFeatureServiceViewController"]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !urlProvided else { return }
        // Ask user for service URL when the sample has loaded.
        var completion: ((Result<URL, Error>) -> Void)!
        completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let serviceURL):
                self.loadService(url: serviceURL)
                self.urlProvided = true
            case .failure(let error):
                let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                let tryAgainAction = UIAlertAction(title: "Try Again", style: .default) { _ in
                    self.askUserForServiceURL(completion: completion)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                alertController.addAction(tryAgainAction)
                alertController.addAction(cancelAction)
                alertController.preferredAction = tryAgainAction
                self.present(alertController, animated: true)
            }
        }
        askUserForServiceURL(completion: completion)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension BrowseOGCAPIFeatureServiceViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

// MARK: - Custom errors

extension BrowseOGCAPIFeatureServiceViewController {
    private enum InputError: LocalizedError {
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Bad URL."
            case .userCancelled:
                return "User cancelled input."
            }
        }
        
        /// Thrown when an invalid URL is entered when the sample loads.
        case invalidURL
        /// Thrown when user cancelled the URL input.
        case userCancelled
    }
}
