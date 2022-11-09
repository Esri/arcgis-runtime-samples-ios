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
import ArcGISToolkit

// MARK: - Calibrate heading and elevation

class ViewHiddenInfrastructureARCalibrationViewController: UIViewController {
    /// The `ArcGISARView` used to display scene and adjust user interactions with camera.
    private let arcgisARView: ArcGISARView
    /// The elevation timer for the "joystick" behavior.
    private var elevationTimer: Timer?
    /// The heading timer for the "joystick" behavior.
    private var headingTimer: Timer?
    /// The heading delta degrees based on the heading slider value.
    private var joystickHeading: Double {
        let deltaHeading = Double(headingSlider.value)
        return Double(signOf: deltaHeading, magnitudeOf: deltaHeading * deltaHeading / 25)
    }
    /// The delta elevation in meters.
    private var joystickElevation: Double {
        let deltaElevation = Double(elevationSlider.value)
        return Double(signOf: -deltaElevation, magnitudeOf: deltaElevation * deltaElevation / 100)
    }
    
    /// The `UISlider` used to adjust elevation.
    private let elevationSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = -20.0
        slider.maximumValue = 20.0
        return slider
    }()
    
    /// The `UISlider` used to adjust heading.
    private let headingSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = -10.0
        slider.maximumValue = 10.0
        return slider
    }()
    
    /// Initialize with an `ArcGISARView` from the parent view controller.
    /// - Parameters:
    ///   - arcgisARView: The `ArcGISARView` used for calibration.
    ///   - isLocal: A Boolean value indicating whether the AR view is in local mode.
    init(arcgisARView: ArcGISARView, isLocal: Bool) {
        self.arcgisARView = arcgisARView
        super.init(nibName: nil, bundle: nil)
        
        // Only make space for the elevation slider when in "Local" mode.
        preferredContentSize = CGSize(width: 250, height: isLocal ? 96 : 48)
        
        // Add the heading label and slider.
        let headingLabel = UILabel()
        headingLabel.text = "Heading:"
        view.addSubview(headingLabel)
        headingLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headingLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 2),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: headingLabel.bottomAnchor, multiplier: 2)
        ])
        view.addSubview(headingSlider)
        headingSlider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headingSlider.leadingAnchor.constraint(equalToSystemSpacingAfter: headingLabel.trailingAnchor, multiplier: 2),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: headingSlider.trailingAnchor, multiplier: 2),
            headingSlider.centerYAnchor.constraint(equalTo: headingLabel.centerYAnchor)
        ])
        
        // Setup actions for the sliders which operate as "joysticks".
        headingSlider.addTarget(self, action: #selector(headingChanged(_:)), for: .valueChanged)
        headingSlider.addTarget(self, action: #selector(touchUpHeading(_:)), for: [.touchUpInside, .touchUpOutside])
        
        // Only "Local" mode support adjusting elevation.
        if isLocal {
            // Add the elevation label and slider.
            let elevationLabel = UILabel()
            elevationLabel.text = "Elevation:"
            view.addSubview(elevationLabel)
            elevationLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                elevationLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 2),
                headingLabel.topAnchor.constraint(equalToSystemSpacingBelow: elevationLabel.bottomAnchor, multiplier: 2)
            ])
            view.addSubview(elevationSlider)
            elevationSlider.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                elevationSlider.leadingAnchor.constraint(equalToSystemSpacingAfter: elevationLabel.trailingAnchor, multiplier: 2),
                view.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: elevationSlider.trailingAnchor, multiplier: 2),
                elevationSlider.centerYAnchor.constraint(equalTo: elevationLabel.centerYAnchor)
            ])
            
            elevationSlider.addTarget(self, action: #selector(elevationChanged(_:)), for: .valueChanged)
            elevationSlider.addTarget(self, action: #selector(touchUpElevation(_:)), for: [.touchUpInside, .touchUpOutside])
        }
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Handle an heading slider valueChanged event.
    ///
    /// - Parameter sender: The slider tapped on.
    @objc
    func headingChanged(_ sender: UISlider) {
        guard headingTimer == nil else { return }
        // Create a timer which rotates the camera when fired.
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.rotateHeading(byDegrees: self.joystickHeading)
        }
        headingTimer = timer
        // Add the timer to the main run loop.
        RunLoop.main.add(timer, forMode: .default)
    }
    
    /// Handle an elevation slider valueChanged event.
    ///
    /// - Parameter sender: The slider tapped on.
    @objc
    func elevationChanged(_ sender: UISlider) {
        guard elevationTimer == nil else { return }
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elevate(byMeters: self.joystickElevation)
        }
        elevationTimer = timer
        RunLoop.main.add(timer, forMode: .default)
    }
    
    /// Handle an elevation slider touchUp event. This will stop the timer.
    ///
    /// - Parameter sender: The slider tapped on.
    @objc
    func touchUpElevation(_ sender: UISlider) {
        elevationTimer?.invalidate()
        elevationTimer = nil
        sender.value = 0.0
    }
    
    /// Handle a heading slider touchUp event. This will stop the timer.
    ///
    /// - Parameter sender: The slider tapped on.
    @objc
    func touchUpHeading(_ sender: UISlider) {
        headingTimer?.invalidate()
        headingTimer = nil
        sender.value = 0.0
    }
    
    /// Rotates the camera by delta heading degrees.
    ///
    /// - Parameter degrees: The degree value to rotate the camera.
    private func rotateHeading(byDegrees degrees: Double) {
        let camera = arcgisARView.originCamera
        let newHeading = camera.heading + degrees
        arcgisARView.originCamera = camera.rotate(
            toHeading: newHeading,
            pitch: camera.pitch,
            roll: camera.roll
        )
    }
    
    /// Change the cameras elevation by delta altitude in meters.
    ///
    /// - Parameter deltaAltitude: The amount to elevate the camera.
    private func elevate(byMeters deltaAltitude: Double) {
        let camera = arcgisARView.originCamera
        arcgisARView.originCamera = camera.elevate(withDeltaAltitude: deltaAltitude)
    }
}
