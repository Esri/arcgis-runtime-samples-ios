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
    // scene
    @IBOutlet weak var sceneView: AGSSceneView! {
        didSet {
            sceneView.scene = makeScene()
            let point = AGSPoint(x: -116.621, y: 24.7773, z: 856977.0, spatialReference: .wgs84())
            let camera = AGSCamera(location: point, heading: 353.994, pitch: 48.5495, roll: 0)
            sceneView.setViewpointCamera(camera)
            sceneView.imageOverlays.add(imageOverlay)
        }
    }
    
    @IBOutlet weak var opacityLabel: UILabel!
    @IBOutlet weak var opacitySlider: UISlider! {
        didSet {
            opacityLabel.text = String(format: "%.0f%%", opacitySlider.value * 100)
        }
    }
    @IBOutlet weak var playPauseButton: UIBarButtonItem!
    @IBOutlet weak var frameRateButton: UIBarButtonItem!
    
    let imageOverlay = AGSImageOverlay()
    /// Delay in milisecond.
    var frameRate = 60.0
    /// urls
    var imageURLs: [URL] = []
    var loopCounter: LoopCounter!
    var pacificSouthwestEnvelope: AGSEnvelope!
    
    private var isAnimating = false {
        didSet {
            playPauseButton?.title = isAnimating ? "Pause" : "Play"
        }
    }
    var frameRateTimer: Timer?
    
    /// Creates a scene.
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
        
        // Create the surface and add it to the scene.
        let surface = AGSSurface()
        surface.elevationSources = [elevationSource]
        scene.baseSurface = surface
        
        let pointForImageFrame = AGSPoint(x: -120.0724273439448, y: 35.131016955536694, spatialReference: .wgs84())
        pacificSouthwestEnvelope = AGSEnvelope(center: pointForImageFrame, width: 15.09589635986124, height: -14.3770441522488)
        
        return scene
    }
    
    func startAnimation(_ fps: Double) {
        // invalidate timer to stop previous ongoing animation
        frameRateTimer?.invalidate()
        
        //duration or interval
        let duration = 1 / Double(fps)
        
        // new timer
        let timer = Timer(timeInterval: duration, repeats: true) { [weak self] _ in
            self?.animate()
        }
        self.frameRateTimer = timer
    }
    
    private func animate() {
        let imageFrame = AGSImageFrame(url: imageURLs[loopCounter.currentIndex], extent: pacificSouthwestEnvelope)
        imageOverlay.imageFrame = imageFrame
        loopCounter.next()
    }
    
    func loadImageURLs() {
//        guard let pacificSouthWestPath = Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "PacificSouthWest") else {
//            return
//        }
        guard let pacificSouthWestPath = Bundle.main.urls(forResourcesWithExtension: "stylx", subdirectory: "Styles") else {
            return
        }
        for item in pacificSouthWestPath {
            print("Found \(item.absoluteString)")
        }
        
        loopCounter = LoopCounter(size: imageURLs.count)
        playPauseButton.isEnabled = true
        frameRateButton.isEnabled = true
        opacitySlider.isEnabled = true
//        opacitySlider.isUserInteractionEnabled = true
    }
    
    // MARK: - Actions
    
    //rotate the map view based on the value of the slider
    @IBAction func sliderValueChanged(_ slider: UISlider) {
        imageOverlay.opacity = slider.value
        opacityLabel.text = String(format: "%.0f%%", slider.value * 100)
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
            ("60 fps", 60.0),
            ("30 fps", 30.0),
            ("15 fps", 15.0)
        ]
        frameRates.forEach { (name, fps) in
            let action = UIAlertAction(title: name, style: .default) { [unowned self] _ in
                // Reset the counter so that it replays from the first frame.
                self.loopCounter.reset()
                self.frameRate = fps
                if self.isAnimating {
                    self.frameRateTimer?.invalidate()
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
        // Load the image URLs from resources directory.
        loadImageURLs()
    }
    
    deinit {
        frameRateTimer?.invalidate()
    }
}

struct LoopCounter {
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
        if currentIndex > size {
            currentIndex = 0
        }
    }
}
