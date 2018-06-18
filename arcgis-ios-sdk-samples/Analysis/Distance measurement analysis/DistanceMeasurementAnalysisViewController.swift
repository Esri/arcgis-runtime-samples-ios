//
// Copyright © 2018 Esri.
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

class DistanceMeasurementAnalysisViewController: UIViewController, AGSGeoViewTouchDelegate {
    /// The scene displayed in the scene view.
    let scene: AGSScene
    /// The location distance measurement analysis.
    let locationDistanceMeasurement: AGSLocationDistanceMeasurement
    
    /// The scene view managed by the view controller.
    @IBOutlet weak var sceneView: AGSSceneView!
    /// The view for displaying distances.
    @IBOutlet weak var distanceView: UIView!
    @IBOutlet weak var directMeasurementLabel: UILabel!
    @IBOutlet weak var horizontalMeasurementLabel: UILabel!
    @IBOutlet weak var verticalMeasurementLabel: UILabel!
    
    required init?(coder: NSCoder) {
        // Create the scene.
        scene = AGSScene(basemap: .imagery())
        
        // Create the surface and set it as the base surface of the scene.
        let elevationSources = [
            AGSArcGISTiledElevationSource(url: .worldElevationService),
            AGSArcGISTiledElevationSource(url: .brestElevationService)
        ]
        let surface = AGSSurface()
        surface.elevationSources.append(contentsOf: elevationSources)
        scene.baseSurface = surface
        
        // Create the building layer and add it to the scene.
        let buildingsLayer = AGSArcGISSceneLayer(url: .brestBuildingsService)
        scene.operationalLayers.add(buildingsLayer)
        
        // Create the location distance measurement.
        let startPoint = AGSPoint(x: -4.494677, y: 48.384472, z: 24.772694, spatialReference: .wgs84())
        let endPoint = AGSPoint(x: -4.495646, y: 48.384377, z: 58.501115, spatialReference: .wgs84())
        locationDistanceMeasurement = AGSLocationDistanceMeasurement(startLocation: startPoint, endLocation: endPoint)
        
        super.init(coder: coder)
        
        locationDistanceMeasurement.measurementChangedHandler = { [weak self] _, _, _ in
            DispatchQueue.main.async {
                self?.updateMeasurementLabels()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure the scene view.
        sceneView.scene = scene
        sceneView.touchDelegate = self
        let lookAtPoint = AGSEnvelope(min: locationDistanceMeasurement.startLocation, max: locationDistanceMeasurement.endLocation).center
        let camera = AGSCamera(lookAt: lookAtPoint, distance: 200, heading: 0, pitch: 45, roll: 0)
        sceneView.setViewpointCamera(camera)
        
        // Create the analysis overlay with the location distance measurement
        // analysis and add it to the scene view.
        let analysisOverlay = AGSAnalysisOverlay()
        analysisOverlay.analyses.add(locationDistanceMeasurement)
        sceneView.analysisOverlays.add(analysisOverlay)
        
        distanceView.backgroundColor = .backgroundGray
        distanceView.tintColor = .primaryBlue
        
        updateMeasurementLabels()
        
        // Add the source code button item to the right of navigation bar.
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["DistanceMeasurementAnalysisViewController"]
    }
    
    @IBAction func unitSystemSegmentedControl(_ sender: UISegmentedControl) {
        guard let unitSystem = AGSUnitSystem(rawValue: sender.selectedSegmentIndex) else { return }
        locationDistanceMeasurement.unitSystem = unitSystem
    }
    
    let measurementFormatter: MeasurementFormatter = {
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.numberFormatter.minimumFractionDigits = 2
        measurementFormatter.numberFormatter.maximumFractionDigits = 2
        return measurementFormatter
    }()
    
    func updateMeasurementLabels() {
        guard isViewLoaded else { return }
        if locationDistanceMeasurement.startLocation != locationDistanceMeasurement.endLocation,
            let directDistance = locationDistanceMeasurement.directDistance,
            let horizontalDistance = locationDistanceMeasurement.horizontalDistance,
            let verticalDistance = locationDistanceMeasurement.verticalDistance {
            directMeasurementLabel.text = measurementFormatter.string(from: Measurement(distance: directDistance))
            horizontalMeasurementLabel.text = measurementFormatter.string(from: Measurement(distance: horizontalDistance))
            verticalMeasurementLabel.text = measurementFormatter.string(from: Measurement(distance: verticalDistance))
        } else {
            directMeasurementLabel.text = "--"
            horizontalMeasurementLabel.text = "--"
            verticalMeasurementLabel.text = "--"
        }
    }
    
    // MARK: AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        sceneView.screen(toLocation: screenPoint) { [weak self] mapLocation in
            guard let measurement = self?.locationDistanceMeasurement else { return }
            if measurement.startLocation != measurement.endLocation {
                measurement.startLocation = mapLocation
            }
            measurement.endLocation = mapLocation
        }
    }
    
    func geoView(_ geoView: AGSGeoView, didLongPressAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        sceneView.screen(toLocation: screenPoint) { [weak self] mapLocation in
            guard let measurement = self?.locationDistanceMeasurement else { return }
            if measurement.startLocation != measurement.endLocation {
                measurement.startLocation = mapLocation
            }
            measurement.endLocation = mapLocation
        }
    }
    
    func geoView(_ geoView: AGSGeoView, didMoveLongPressToScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        sceneView.screen(toLocation: screenPoint) { [weak self] mapLocation in
            self?.locationDistanceMeasurement.endLocation = mapLocation
        }
    }
}

extension Measurement where UnitType == Unit {
    /// Creates a measurement from an ArcGIS distance.
    ///
    /// - Parameter distance: An `AGSDistance` object.
    init(distance: AGSDistance) {
        let unit = Unit(symbol: distance.unit.abbreviation)
        let value = distance.value
        self.init(value: value, unit: unit)
    }
}
