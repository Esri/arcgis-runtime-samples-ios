//
//  CreateTerrainSurfaceFromLocalTilePackageViewController.swift
//  ArcGIS Runtime SDK Samples
//
//  Created by Vivian Quach on 7/2/19.
//  Copyright © 2019 Esri. All rights reserved.
//

import Foundation
import ArcGIS

class CreateTerrainSurfaceFromLocalTilePackageViewController: UIViewController {
    @IBOutlet weak var sceneView: AGSSceneView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["CreateTerrainSurfaceFromLocalTilePackageViewController"]
        setupScene()
    }
    private func setupScene() {
        let scene = AGSScene(basemapType: .imageryWithLabels)
        sceneView.scene = scene
        
        let camera = AGSCamera(latitude: 33.950896, longitude: -118.525341, altitude: 16000.0, heading: 0, pitch: 50, roll: 0)
        sceneView.setViewpointCamera(camera)
    }
}
