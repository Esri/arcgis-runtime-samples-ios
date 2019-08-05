//
// Copyright © 2019 Esri.
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
//

import UIKit
import ArcGIS

/// A view controller that manages the interface of the Control Annotation
/// Sublayer Visibility sample.
class ControlAnnotationSublayerVisibilityViewController: UIViewController {
    /// The map view managed by the view controller.
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            loadMobileMapPackage()
        }
    }
    /// The label that display's the map view's map scale.
    @IBOutlet weak var currentMapScaleLabel: UILabel!
    /// The bar button item that presents the sublayers view controller.
    @IBOutlet weak var sublayersButtonItem: UIBarButtonItem!
    
    /// The mobile map package used by this sample.
    let mobileMapPackage = AGSMobileMapPackage(fileURL: Bundle.main.url(forResource: "GasDeviceAnno", withExtension: "mmpk")!)
    /// The sublayers of the annotation layer. Will be empty until the
    /// annotation layer has finished loading.
    var annotationSublayers = [AGSAnnotationSublayer]()
    /// The observation of the map view's map scale.
    var mapScaleObservation: NSKeyValueObservation?
    
    /// The formatter used to generate strings from scale values.
    private let scaleFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 0
        return numberFormatter
    }()
    
    /// Initiates loading of the mobile map package.
    func loadMobileMapPackage() {
        mobileMapPackage.load { [weak self] (result: Result<Void, Error>) in
            self?.mobileMapPackageDidLoad(with: result)
        }
    }
    
    /// Called in response to the mobile map package load operation completing.
    ///
    /// - Parameter result: The result of the load operation.
    func mobileMapPackageDidLoad(with result: Result<Void, Error>) {
        switch result {
        case .success:
            let map = mobileMapPackage.maps.first
            mapView.map = map
            if let annotationLayer = map?.operationalLayers.first(where: { $0 is AGSAnnotationLayer }) as? AGSAnnotationLayer {
                annotationLayer.load { [weak self, unowned annotationLayer] (result: Result<Void, Error>) in
                    self?.annotationLayer(annotationLayer, didLoadWith: result)
                }
            }
            sublayersButtonItem.isEnabled = true
        case .failure(let error):
            presentAlert(error: error)
        }
    }
    
    /// Called in response to the annotation layer load operation completing.
    ///
    /// - Parameters:
    ///   - annotationLayer: The annotation layer that finished loading.
    ///   - result: The result of the load operation.
    func annotationLayer(_ annotationLayer: AGSAnnotationLayer, didLoadWith result: Result<Void, Error>) {
        switch result {
        case .success:
            annotationSublayers.append(contentsOf: annotationLayer.subLayerContents.compactMap { $0 as? AGSAnnotationSublayer })
            sublayersButtonItem.isEnabled = true
        case .failure(let error):
            presentAlert(error: error)
        }
    }
    
    /// Called in response to the map view's map scale changing.
    func mapScaleDidChange() {
        // Update the text of the Current Map Scale label.
        let mapScale = mapView.mapScale
        currentMapScaleLabel.text = String(format: "1:%@", scaleFormatter.string(from: mapScale as NSNumber)!)
        // Inform the sublayers view controller of the new map scale.
        let sublayersViewController = self.presentedViewController as? ControlAnnotationSublayerVisibilitySublayersViewController
        sublayersViewController?.mapScale = mapScale
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = [
            "ControlAnnotationSublayerVisibilityViewController",
            "ControlAnnotationSublayerVisibilitySublayersViewController",
            "ControlAnnotationSublayerVisibilitySublayerCell"
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapScaleObservation = mapView.observe(\.mapScale, options: .initial) { [weak self] (_, _) in
            DispatchQueue.main.async { self?.mapScaleDidChange() }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        mapScaleObservation = nil
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let sublayersViewController = segue.destination as? ControlAnnotationSublayerVisibilitySublayersViewController {
            sublayersViewController.annotationSublayers = annotationSublayers
            sublayersViewController.mapScale = mapView.mapScale
            if let popoverPresentationController = sublayersViewController.popoverPresentationController {
                popoverPresentationController.delegate = self
                popoverPresentationController.passthroughViews = [mapView]
            }
        }
    }
}

extension ControlAnnotationSublayerVisibilityViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

private extension AGSLoadable {
    func load(completion: @escaping (Result<Void, Error>) -> Void) {
        load { (error: Error?) in
            let result: Result<Void, Error>
            if let error = error {
                result = .failure(error)
            } else {
                result = .success(())
            }
            completion(result)
        }
    }
}
