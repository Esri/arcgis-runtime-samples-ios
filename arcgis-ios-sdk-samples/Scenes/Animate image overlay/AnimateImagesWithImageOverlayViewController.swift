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
    /// The button to choose a frame rate for the animation
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
    
    /// The frame rate in the unit of frame per second.
    var frameRate = 60
    /// A timer to synchronize image frame animation to the refresh rate of the display.
    var displaylink: CADisplayLink?
    /// The image overlay to show image frames.
    let imageOverlay = AGSImageOverlay()
    /// An iterator to hold and loop through the overlay images.
    private lazy var imagesIterator: CircularIterator<UIImage> = {
        // Get the URLs to those images added to the project's folder reference.
        let pacificSouthWestURLs = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "PacificSouthWest") ?? []
        // Sort the image URLs by their relative pathnames.
        let imageURLs = pacificSouthWestURLs.sorted { $0.lastPathComponent < $1.lastPathComponent }
        return CircularIterator(
            elements: imageURLs.map { UIImage(contentsOfFile: $0.path)! }
        )
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

    /// A boolean which indicates whether the animation is playing or paused.
    var isAnimating = false {
        didSet {
            if isAnimating {
                let index = toolbar.items!.firstIndex(of: playButtonItem)!
                toolbar.items![index] = pauseButtonItem
            } else {
                let index = toolbar.items!.firstIndex(of: pauseButtonItem)!
                toolbar.items![index] = playButtonItem
            }
        }
    }
    
    // MARK: Initialize scene and animation
    
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
        // Create a surface and add it to the scene.
        let surface = AGSSurface()
        surface.elevationSources = [elevationSource]
        let scene = AGSScene(basemap: AGSBasemap(baseLayer: worldDarkGrayBasemap))
        scene.baseSurface = surface
        return scene
    }
    
    func startAnimation(fps: Int) {
        // Invalidate display link to stop previous ongoing animation.
        displaylink?.invalidate()
        // Create a new display link.
        displaylink = CADisplayLink(target: self, selector: #selector(setImageFrame))
        // Set frame rate to 15, 30 or 60 frames per second.
        displaylink!.preferredFramesPerSecond = fps
        // Add to main thread common mode run loop, so it is not effected by UI events.
        displaylink!.add(to: .main, forMode: .common)
    }
    
    /// Set current image to the image overlay.
    @objc
    func setImageFrame() {
        let frame = AGSImageFrame(image: imagesIterator.next()!, extent: pacificSouthwestEnvelope)
        imageOverlay.imageFrame = frame
    }
    
    func getOpacityPercentageString(percentage: Float) -> String {
        return percentageFormatter.string(from: percentage as NSNumber)!
    }
    
    // MARK: - Actions
    
    @IBAction func sliderValueChanged(_ slider: UISlider) {
        imageOverlay.opacity = slider.value
        opacityLabel.text = getOpacityPercentageString(percentage: slider.value)
    }
    
    @IBAction func playPauseButtonTapped(_ button: UIBarButtonItem) {
        if isAnimating {
            displaylink?.invalidate()
        } else {
            startAnimation(fps: frameRate)
        }
        isAnimating.toggle()
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
                self.frameRate = fps
                if self.isAnimating {
                    self.startAnimation(fps: fps)
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
        // Load the images from resources directory, and set UI if the load succeeded.
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Invalidates display link before exiting the sample.
        displaylink?.invalidate()
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
