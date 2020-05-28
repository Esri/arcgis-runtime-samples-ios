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

class AnimateImagesWithImageOverlayViewController: UIViewController {
    // MARK: Storyboard views
    
    /// The button to play image overlay animation.
    @IBOutlet var playButtonItem: UIBarButtonItem!
    /// The button to pause image overlay animation.
    @IBOutlet var pauseButtonItem: UIBarButtonItem!
    /// The button to choose a playback speed for the animation.
    @IBOutlet weak var speedButtonItem: UIBarButtonItem!
    /// The toolbar in the view controller.
    @IBOutlet weak var toolbar: UIToolbar!
    /// The label to display opacity level.
    @IBOutlet weak var opacityLabel: UILabel!
    
    /// The slider to change opacity level, from transparent 0% to opaque 100%.
    @IBOutlet weak var opacitySlider: UISlider! {
        didSet {
            sliderValueChanged(opacitySlider)
        }
    }
    
    /// The scene view managed by the view controller.
    @IBOutlet weak var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene()
            let point = AGSPoint(x: -116.621, y: 24.7773, z: 856977.0, spatialReference: .wgs84())
            let camera = AGSCamera(location: point, heading: 353.994, pitch: 48.5495, roll: 0)
            sceneView.setViewpointCamera(camera)
            sceneView.imageOverlays.add(imageOverlay)
        }
    }
    
    // MARK: Instance properties

    /// The image overlay to show image frames.
    let imageOverlay = AGSImageOverlay()
    /// A timer to synchronize image frame animation to the refresh rate of the display.
    var displayLink: CADisplayLink!
    
    /// An iterator to hold and loop through the overlay images.
    private lazy var imagesIterator: CircularIterator<UIImage> = {
        // Get the URLs to images added to the project's folder reference.
        let imageURLs = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "PacificSouthWest") ?? []
        let images = imageURLs
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .map { UIImage(contentsOfFile: $0.path)! }
        return CircularIterator(elements: images)
    }()
    
    /// A formatter to format percentage strings.
    let percentageFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.multiplier = 100
        return formatter
    }()
    
    /// An envelope of the pacific southwest sector for displaying the image frame.
    let pacificSouthwestEnvelope = AGSEnvelope(
        center: AGSPoint(
            x: -120.0724273439448,
            y: 35.131016955536694,
            spatialReference: .wgs84()
        ),
        width: 15.09589635986124,
        height: -14.3770441522488
    )
    
    // MARK: Initialize scene and set image frame
    
    /// Create a scene.
    ///
    /// - Returns: A new `AGSScene` object.
    func makeScene() -> AGSScene {
        // Create a tiled layer from World Dark Gray Base REST service.
        let basemapTileURL = URL(string: "https://services.arcgisonline.com/arcgis/rest/services/Canvas/World_Dark_Gray_Base/MapServer")!
        let worldDarkGrayBasemap = AGSArcGISTiledLayer(url: basemapTileURL)
        // Create an elevation source from Terrain3D REST service.
        let elevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationServiceURL)
        let surface = AGSSurface()
        surface.elevationSources = [elevationSource]
        let scene = AGSScene(basemap: AGSBasemap(baseLayer: worldDarkGrayBasemap))
        scene.baseSurface = surface
        return scene
    }
    
    /// Create a display link timer for the image frame animation.
    ///
    /// - Returns: A new `CADisplayLink` object.
    func makeDisplayLink() -> CADisplayLink {
        let newDisplayLink = CADisplayLink(target: self, selector: #selector(setImageFrame))
        // Inherit the frame rate from existing display link, or set to default 60 fps.
        newDisplayLink.preferredFramesPerSecond = displayLink?.preferredFramesPerSecond ?? 60
        newDisplayLink.isPaused = true
        // Add to main thread common mode run loop, so it is not effected by UI events.
        newDisplayLink.add(to: .main, forMode: .common)
        return newDisplayLink
    }
    
    /// Set current image to the image overlay.
    @objc
    func setImageFrame() {
        let frame = AGSImageFrame(image: imagesIterator.next()!, extent: pacificSouthwestEnvelope)
        imageOverlay.imageFrame = frame
    }
    
    // MARK: - Actions
    
    @IBAction func sliderValueChanged(_ slider: UISlider) {
        imageOverlay.opacity = slider.value
        opacityLabel.text = percentageFormatter.string(from: slider.value as NSNumber)!
    }
    
    @IBAction func playPauseButtonTapped(_ button: UIBarButtonItem) {
        let index = toolbar.items!.firstIndex(of: button)!
        if !displayLink.isPaused {
            toolbar.items![index] = playButtonItem
        } else {
            toolbar.items![index] = pauseButtonItem
        }
        displayLink.isPaused.toggle()
    }
    
    @IBAction func speedButtonTapped(_ button: UIBarButtonItem) {
        let alertController = UIAlertController(
            title: "Choose playback speed.",
            message: nil,
            preferredStyle: .actionSheet
        )
        let speedChoices: [(name: String, fps: Int)] = [
            ("Fast", 60),
            ("Medium", 30),
            ("Slow", 15)
        ]
        speedChoices.forEach { (name, fps) in
            let action = UIAlertAction(title: name, style: .default) { _ in
                if !self.displayLink.isPaused {
                    self.displayLink.preferredFramesPerSecond = fps
                }
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = speedButtonItem
        present(alertController, animated: true)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["AnimateImagesWithImageOverlayViewController"]
        // Set UI if the load succeeds.
        if !imagesIterator.elements.isEmpty {
            playButtonItem.isEnabled = true
            speedButtonItem.isEnabled = true
            opacitySlider.isEnabled = true
            // Load the first frame into the scene.
            setImageFrame()
        } else {
            presentAlert(title: "Error", message: "Fail to load images.")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        displayLink = makeDisplayLink()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Pause the animation and change the tool bar button.
        if !displayLink.isPaused {
            playPauseButtonTapped(pauseButtonItem)
        }
        // Invalidates display link before exiting.
        displayLink.invalidate()
    }
}

/// A generic circular iterator.
private struct CircularIterator<Element>: IteratorProtocol {
    let elements: [Element]
    private var elementIterator: Array<Element>.Iterator
    
    init(elements: [Element]) {
        self.elements = elements
        elementIterator = elements.makeIterator()
    }
    
    mutating func next() -> Element? {
        if let next = elementIterator.next() {
            return next
        } else {
            elementIterator = elements.makeIterator()
            return elementIterator.next()
        }
    }
}
