//
// Copyright 2016 Esri.
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

class BlendRendererViewController: UIViewController, BlendRendererSettingsViewControllerDelegate {
    @IBOutlet var mapView: AGSMapView!

    let imageryBasemapLayer: AGSRasterLayer = {
        let raster = AGSRaster(name: "Shasta", extension: "tif")
        return AGSRasterLayer(raster: raster)
    }()
    let elevationBasemapLayer: AGSRasterLayer = {
        let raster = AGSRaster(name: "Shasta_Elevation", extension: "tif")
        return AGSRasterLayer(raster: raster)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //add the source code button item to the right of navigation bar
        (navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["BlendRendererViewController", "BlendRendererSettingsViewController", "OptionsTableViewController"]
        
        //initialize map
        let map = AGSMap()
        //assign map to the map view
        mapView.map = map
        
        // set the initial blend renderer
        setBlendRenderer(altitude: 0, azimuth: 0, slopeType: .none, colorRampType: .none)
    }
    
    /// The color ramp type that was used to create the currently applied blend renderer.
    private var displayedColorRampType: AGSPresetColorRampType = .none

    // MARK: - BlendRendererSettingsViewControllerDelegate
    
    func blendRendererSettingsViewController(_ blendRendererSettingsVC: BlendRendererSettingsViewController, selectedAltitude altitude: Double, azimuth: Double, slopeType: AGSSlopeType, colorRampType: AGSPresetColorRampType) {
        setBlendRenderer(altitude: altitude, azimuth: azimuth, slopeType: slopeType, colorRampType: colorRampType)
    }
    
    private func setBlendRenderer(altitude: Double, azimuth: Double, slopeType: AGSSlopeType, colorRampType: AGSPresetColorRampType) {
        displayedColorRampType = colorRampType
        
        // create a colorRamp object from the type specified
        let colorRamp = colorRampType != .none ? AGSColorRamp(type: colorRampType, size: 800) : nil
        
        // the raster to use for blending
        let elevationRaster = AGSRaster(name: "Shasta_Elevation", extension: "tif")
        
        // create a blend renderer
        let blendRenderer = AGSBlendRenderer(
            elevationRaster: elevationRaster,
            outputMinValues: [9],
            outputMaxValues: [255],
            sourceMinValues: [],
            sourceMaxValues: [],
            noDataValues: [],
            gammas: [],
            colorRamp: colorRamp,
            altitude: altitude,
            azimuth: azimuth,
            zFactor: 1,
            slopeType: slopeType,
            pixelSizeFactor: 1,
            pixelSizePower: 1,
            outputBitDepth: 8)
        
        // remove the exisiting layers
        mapView.map?.basemap.baseLayers.removeAllObjects()
        
        // if the colorRamp type is .none, then use the imagery for blending.
        // else use the elevation
        let rasterLayer = colorRampType == .none ? imageryBasemapLayer : elevationBasemapLayer
        
        // apply the blend renderer on this new raster layer
        rasterLayer.renderer = blendRenderer

        // add the raster layer to the basemap
        mapView.map?.basemap.baseLayers.add(rasterLayer)
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navController = segue.destination as? UINavigationController,
            let controller = navController.viewControllers.first as? BlendRendererSettingsViewController,
            let rasterLayer = mapView.map?.basemap.baseLayers.firstObject as? AGSRasterLayer,
            let renderer = rasterLayer.renderer as? AGSBlendRenderer {
            controller.preferredContentSize = {
                let height: CGFloat
                if traitCollection.horizontalSizeClass == .regular,
                    traitCollection.verticalSizeClass == .regular {
                    height = 250
                } else {
                    height = 200
                }
                return CGSize(width: 375, height: height)
            }()
            navController.presentationController?.delegate = self
            controller.delegate = self
            controller.altitude = renderer.altitude
            controller.azimuth = renderer.azimuth
            controller.slopeType = renderer.slopeType
            controller.colorRampType = displayedColorRampType
        }
    }
}

extension BlendRendererViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}
