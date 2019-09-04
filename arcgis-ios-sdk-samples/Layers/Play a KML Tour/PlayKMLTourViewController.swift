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

/// A view controller that manages the interface of the Play a KML Tour sample.
class PlayKMLTourViewController: UIViewController {
    /// The scene view managed by the view controller.
    @IBOutlet weak var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene(kmlDataset: dataset)
        }
    }
    /// The toolbar containing the button items for controlling the tour.
    @IBOutlet var toolbar: UIToolbar!
    /// A bar button item that resets the tour.
    @IBOutlet var rewindButtonItem: UIBarButtonItem!
    /// A bar button item that starts or resumes the tour.
    @IBOutlet var playButtonItem: UIBarButtonItem!
    /// A bar button item that pauses the tour.
    @IBOutlet var pauseButtonItem: UIBarButtonItem!
    
    /// The controller of the tour.
    var tourController: AGSKMLTourController!
    
    /// The data set in which to find the tour.
    lazy var dataset: AGSKMLDataset = { [unowned self] in
        let url = URL(string: "https://www.arcgis.com/sharing/rest/content/items/f10b1d37fdd645c9bc9b189fb546307c/data")!
        let dataset = AGSKMLDataset(url: url)
        dataset.load { _ in self.datasetDidLoad() }
        return dataset
    }()
    
    /// Called in response to the dataset load operation completing.
    func datasetDidLoad() {
        if let error = dataset.loadError {
            presentAlert(error: error)
        } else if let tour = dataset.tours.first {
            tourStatusObservation = tour.observe(\.tourStatus, options: .initial) { [weak self] (_, _) in
                DispatchQueue.main.async { self?.tourStatusDidChange() }
            }
            tourController = makeTourController(tour: tour)
        }
    }
    
    /// Makes a scene with a KML layer from the given dataset.
    ///
    /// - Parameter kmlDataset: A KML dataset.
    /// - Returns: A new `AGSScene` object.
    func makeScene(kmlDataset: AGSKMLDataset) -> AGSScene {
        let scene = AGSScene(basemap: .imagery())
        
        let elevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationServiceURL)
        scene.baseSurface?.elevationSources.append(elevationSource)
        
        let kmlLayer = AGSKMLLayer(kmlDataset: kmlDataset)
        scene.operationalLayers.add(kmlLayer)
        
        return scene
    }
    
    /// Creates a KML tour controller with the given KML tour.
    ///
    /// - Parameter tour: A KML tour.
    /// - Returns: A new `AGSKMLTourController` object.
    func makeTourController(tour: AGSKMLTour) -> AGSKMLTourController {
        let tourController = AGSKMLTourController()
        tourController.tour = tour
        return tourController
    }
    
    /// Resets the tour to the beginning.
    @IBAction func rewind() {
        let wasPlaying = tourController.tour!.tourStatus == .playing
        tourController.reset()
        if wasPlaying {
            tourController.play()
        }
    }
    
    /// Starts or resumes the tour.
    @IBAction func play() {
        tourController.play()
    }
    
    /// Pauses the tour.
    @IBAction func pause() {
        tourController.pause()
    }
    
    /// The observation of the tour status.
    var tourStatusObservation: NSKeyValueObservation?
    
    /// Called in response to the tour status changing.
    func tourStatusDidChange() {
        let playPauseButtonItem: UIBarButtonItem
        switch tourController.tour!.tourStatus {
        case .notInitialized, .initializing:
            rewindButtonItem.isEnabled = false
            playButtonItem.isEnabled = false
            playPauseButtonItem = playButtonItem
        case .initialized, .paused, .completed:
            rewindButtonItem.isEnabled = tourController.tour!.tourStatus != .initialized
            playButtonItem.isEnabled = true
            playPauseButtonItem = playButtonItem
        case .playing:
            rewindButtonItem.isEnabled = true
            playPauseButtonItem = pauseButtonItem
        @unknown default:
            return
        }
        let indexOfPlayPause = toolbar.items!.midIndex
        toolbar.items![indexOfPlayPause] = playPauseButtonItem
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["PlayKMLTourViewController"]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tourController?.pause()
    }
}

private extension AGSKMLDataset {
    /// Returns all tours found in the dataset.
    var tours: [AGSKMLTour] {
        return rootNodes.reduce(into: []) { (tours, node) in
            switch node {
            case let tour as AGSKMLTour:
                tours.append(tour)
            case let container as AGSKMLContainer:
                tours.append(contentsOf: container.tours)
            default:
                break
            }
        }
    }
}

private extension AGSKMLContainer {
    /// Returns all tours found in the container.
    var tours: [AGSKMLTour] {
        return childNodes.reduce(into: []) { (tours, node) in
            switch node {
            case let tour as AGSKMLTour:
                tours.append(tour)
            case let container as AGSKMLContainer:
                tours.append(contentsOf: container.tours)
            default:
                break
            }
        }
    }
}

private extension Collection {
    /// The position of the middle element in a nonempty collection.
    var midIndex: Index {
        return index(startIndex, offsetBy: distance(from: startIndex, to: endIndex) / 2)
    }
}
