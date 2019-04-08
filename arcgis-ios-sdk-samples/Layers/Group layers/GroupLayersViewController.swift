// Copyright 2019 Esri.
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

class GroupLayersViewController: UIViewController {
    @IBOutlet var sceneView: AGSSceneView!
    @IBOutlet var layersBarButtonItem: UIBarButtonItem!
    
    let scene: AGSScene
    let groupLayerName = "Dev A"
    
    required init?(coder aDecoder: NSCoder) {
        // Initialize a scene with imagery basemap.
        scene = AGSScene(basemap: .imagery())
        
        // Add base surface to the scene for elevation data.
        let surface = AGSSurface()
        let worldElevationServiceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: worldElevationServiceURL)
        surface.elevationSources.append(elevationSource)
        scene.baseSurface = surface
        
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["GroupLayersViewController", "LayersTableViewController"]
        
        // Assign the scene to the sceneView.
        sceneView.scene = scene
    
        addOperationalLayers()
        zoomToGroupLayer()
    }
    
    /// Zooms to the extent of the Group Layer when its child layers are loaded.
    func zoomToGroupLayer() {
        guard let groupLayer = (scene.operationalLayers as! [AGSLayer]).first(where: { $0.name == groupLayerName }) as? AGSGroupLayer else {
            return
        }
        
        guard let childLayers = groupLayer.layers as? [AGSLayer] else { return }
        
        AGSLoadObjects(childLayers) { [weak self] (success) in
            guard success == true else {
                print("Error loading layers")
                return
            }
            if let extent = groupLayer.fullExtent {
                let camera = AGSCamera(lookAt: extent.center, distance: 700, heading: 0, pitch: 60, roll: 0)
                
                // Zoom to the viewpoint specified by the camera position.
                self?.sceneView.setViewpointCamera(camera, completion: { (_) in
                    DispatchQueue.main.async {
                        // Enable the bar button item to display
                        // the Table of Contents of operational layers.
                        self?.layersBarButtonItem.isEnabled = true
                    }
                })
            }
        }
    }
    
    /// Adds a group layer and other layers to the scene as operational layers.
    func addOperationalLayers() {
        let sceneLayer = AGSArcGISSceneLayer(url: URL(string: "https://scenesampleserverdev.arcgis.com/arcgis/rest/services/Hosted/PlannedDemo_BuildingShell/SceneServer/layers/0")!)
        
        let featureTable = AGSServiceFeatureTable(url: URL(string: "https://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/DevelopmentProjectArea/FeatureServer/0")!)
        let featureLayer = AGSFeatureLayer(featureTable: featureTable)
        
        scene.operationalLayers.addObjects(from: [makeGroupLayer(), sceneLayer, featureLayer])
    }
    
    /// Returns a group layer.
    func makeGroupLayer() -> AGSGroupLayer {
        // Create a group layer and set its name.
        let groupLayer = AGSGroupLayer()
        groupLayer.name = groupLayerName
        
        // Create two scene layers.
        let trees = AGSArcGISSceneLayer(url: URL(string: "https://scenesampleserverdev.arcgis.com/arcgis/rest/services/Hosted/DevA_Trees/SceneServer/layers/0")!)
        let pathways = AGSArcGISSceneLayer(url: URL(string: "https://scenesampleserverdev.arcgis.com/arcgis/rest/services/Hosted/DevA_Pathways/SceneServer/layers/0")!)
        
        // Create a feature layer.
        let buildings = AGSArcGISSceneLayer(url: URL(string: "https://scenesampleserverdev.arcgis.com/arcgis/rest/services/Hosted/DevA_BuildingShell_Textured/SceneServer/layers/0")!)
        
        // Add the scene layers and feature layer as children of the group layer.
        groupLayer.layers.add(trees)
        groupLayer.layers.add(pathways)
        groupLayer.layers.add(buildings)
        
        return groupLayer
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LayersPopover" {
            guard let controller = segue.destination as? LayersTableViewController else { return }
            
            if let layers = scene.operationalLayers as? [AGSLayer] {
                controller.layers.append(contentsOf: layers)
            }
            
            // Popover presentation logic.
            controller.presentationController?.delegate = self
            controller.preferredContentSize = CGSize(width: 300, height: 200)
        }
    }
}

extension GroupLayersViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        // For popover or non modal presentation.
        return .none
    }
}
