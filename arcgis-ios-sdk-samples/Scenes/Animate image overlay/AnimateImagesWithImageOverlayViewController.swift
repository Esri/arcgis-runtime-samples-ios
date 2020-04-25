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
    @IBOutlet weak var playPauseButton: UIBarButtonItem!
    @IBOutlet weak var frameRateButton: UIBarButtonItem!
    @IBOutlet weak var opacityLabel: UILabel!
    @IBOutlet weak var opacitySlider: UISlider! {
        didSet {
            opacityLabel.text = getOpacityString()
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
    
    /// A circular loop counter within a length.
    private var loopCounter: LoopCounter!
    /// The graphics overlay used to show a graphic at the tapped point.
    let imageOverlay = AGSImageOverlay()
    /// The Frame delay in milisecond.
    var frameRate = 60.0
    /// An array to hold the URLs for the overlay images.
    var imageURLs: [URL] = []
    /// An envelope of the pacific southwest sector for displaying the image frame.
    var pacificSouthwestEnvelope: AGSEnvelope!
    /// A timer which repeatedly calls setImageFrame for a given period.
    var frameRateTimer: Timer?
    /// A boolean which indicates whether the animation is playing or paused.
    var isAnimating = false {
        didSet {
            playPauseButton?.title = isAnimating ? "Pause" : "Play"
        }
    }
    
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
        let scene = AGSScene(basemap: AGSBasemap(baseLayer: worldDarkGrayBasemap))
        // Create a surface and add it to the scene.
        let surface = AGSSurface()
        surface.elevationSources = [elevationSource]
        scene.baseSurface = surface
        // Create an envelope of the pacific southwest sector for displaying the image frame.
        let pointForImageFrame = AGSPoint(x: -120.0724273439448, y: 35.131016955536694, spatialReference: .wgs84())
        pacificSouthwestEnvelope = AGSEnvelope(center: pointForImageFrame, width: 15.09589635986124, height: -14.3770441522488)
        return scene
    }
    
    func startAnimation(_ fps: Double) {
        // Invalidate timer to stop previous ongoing animation.
        frameRateTimer?.invalidate()
        // Duration or interval between frames in seconds.
        let duration = 1 / Double(fps)
        let timer = Timer(timeInterval: duration, repeats: true) { [weak self] _ in
            self?.setImageFrame()
        }
        self.frameRateTimer = timer
        // Add the timer to common mode run loop, so the timer is not effected by UI events.
        RunLoop.main.add(timer, forMode: .common)
    }
    
    /// Load the URLs for the overlay images.
    ///
    /// - Parameter completion: If it loads successfully, enable the UI components in the completion closure.
    func loadImageURLs(completion: () -> Void) {
        // The images need to be added to the project with folder reference.
        guard let pacificSouthWestURLs = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "PacificSouthWest") else {
            return
        }
        // Sort the image URLs by their relative pathnames.
        imageURLs = pacificSouthWestURLs.sorted { $0.relativeString < $1.relativeString }
        completion()
    }
    
    /// Set the image at current index to the image overlay.
    func setImageFrame() {
        let imageFrame = AGSImageFrame(url: imageURLs[loopCounter.currentIndex], extent: pacificSouthwestEnvelope)
        imageOverlay.imageFrame = imageFrame
        loopCounter.next()
    }
    
    func getOpacityString() -> String {
        return String(format: "Opacity: %.0f%%", opacitySlider.value * 100)
    }
    
    // MARK: - Actions
    
    @IBAction func sliderValueChanged(_ slider: UISlider) {
        imageOverlay.opacity = slider.value
        opacityLabel.text = getOpacityString()
    }
    
    @IBAction func playPauseButtonTapped(_ button: UIBarButtonItem) {
        if isAnimating {
            frameRateTimer?.invalidate()
        } else {
            startAnimation(frameRate)
        }
        isAnimating.toggle()
    }
    
    @IBAction func frameRateButtonTapped(_ button: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Select frame rate", message: nil, preferredStyle: .actionSheet)
        // The playback delay in milisecond.
        let frameRates: [(name: String, fps: Double)] = [
            ("60 FPS", 60.0),
            ("30 FPS", 30.0),
            ("15 FPS", 15.0)
        ]
        frameRates.forEach { (name, fps) in
            let action = UIAlertAction(title: name, style: .default) { [unowned self] _ in
                // Reset the counter so that it replays from the first frame.
                self.loopCounter.reset()
                self.frameRate = fps
                self.frameRateButton.title = name
                if self.isAnimating {
                    self.startAnimation(fps)
                }
            }
            alertController.addAction(action)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        alertController.popoverPresentationController?.barButtonItem = frameRateButton
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = ["AnimateImagesWithImageOverlayViewController"]
        frameRateButton.title = "60 FPS"
        // Load the image URLs from resources directory, and set UI if the load succeeded.
        loadImageURLs {
            loopCounter = LoopCounter(size: imageURLs.count)
            playPauseButton.isEnabled = true
            frameRateButton.isEnabled = true
            opacitySlider.isEnabled = true
        }
        setImageFrame()
    }
    
    deinit {
        // Invalidates the timer before exiting the sample.
        frameRateTimer?.invalidate()
    }
}

/// A circular loop counter within a length.
private struct LoopCounter {
    var currentIndex: Int
    let size: Int
    
    init(size: Int) {
        self.currentIndex = 0
        self.size = size
    }
    
    mutating func reset() {
        currentIndex = 0
    }
    
    mutating func next() {
        currentIndex += 1
        if currentIndex == size {
            currentIndex = 0
        }
    }
}
