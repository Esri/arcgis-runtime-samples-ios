// Copyright 2018 Esri.
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

class ListKMLContentsSceneViewController: UIViewController {
    
    @IBOutlet weak var sceneView: AGSSceneView? {
        didSet {
            sceneView?.scene = scene
        }
    }
    
    private let scene: AGSScene = {
        
        // initialize scene with labeled imagery
        let scene = AGSScene(basemapType: .imageryWithLabels)
        
        // create an elevation source and add it to the scene's surface
        let elevationSourceURL = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer")!
        let elevationSource = AGSArcGISTiledElevationSource(url: elevationSourceURL)
        scene.baseSurface?.elevationSources.append(elevationSource)
        
        return scene
    }()
    
    var kmlDataset: AGSKMLDataset? {
        didSet {
            guard kmlDataset != oldValue,
                let kmlDataset = kmlDataset else {
                    return
            }
            
            // clear any existing layers
            scene.operationalLayers.removeAllObjects()
            
            // create a layer to display the dataset
            let kmlLayer = AGSKMLLayer(kmlDataset: kmlDataset)
            // add the kml layer to the scene
            scene.operationalLayers.add(kmlLayer)
        }
    }
    var node: AGSKMLNode? {
        didSet {
            guard kmlDataset != oldValue,
                let node = node else{
                return
            }
            // set the title so the name will appear in the navigation bar
            title = node.name
                
            // set the viewpoint based on the new node
            setSceneViewpoint(for: node)
        }
    }
    
    /// A queue for calculating the node viewpoint in the background.
    private let dispatchQueue = DispatchQueue(label: "node viewpoint getter", qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    //MARK: - Viewpoint
    
    /// Sets the viewpoint of the scene based on the node, or hides the node
    /// if a viewpoint cannot be determined.
    private func setSceneViewpoint(for node:AGSKMLNode){
        
        dispatchQueue.async {
            // get the viewpoint asynchronously so not to block the main thread
            let nodeViewpoint = self.viewpoint(for: node)
            
            // run UI updates on the main thread
            DispatchQueue.main.async {
                
                // load the view before setting a viewpoint
                self.loadViewIfNeeded()
                
                guard let sceneView = self.sceneView else {
                    return
                }
                
                if let nodeViewpoint = nodeViewpoint,
                    !nodeViewpoint.targetGeometry.isEmpty {
                    
                    // reveal the view in case it was previously hidden
                    sceneView.isHidden = false
                    
                    // set the viewpoint for the node
                    sceneView.setViewpoint(nodeViewpoint)
                }
                else {
                    // this node has no viewpoint so hide the scene view, showing the info text
                    sceneView.isHidden = true
                }
            }
        }
    }
    
    /// Returns the elevation of the scene's surface corresponding to the point's x/y.
    private func sceneSurfaceElevation(for point: AGSPoint) -> Double? {
        guard let surface = scene.baseSurface else {
            return nil
        }
        
        var surfaceElevation: Double? = nil
        let group = DispatchGroup()
        group.enter()
        // we want to return the elevation synchronously, so run the task in the background and wait
        surface.elevation(for: point, completion: { (elevation, error) in
            if error == nil{
                surfaceElevation = elevation
            }
            group.leave()
        })
        // wait, but not longer than three seconds
        _ = group.wait(timeout: .now() + 3)
        return surfaceElevation
    }
    
    /// Returns the viewpoint showing the node, converting it from the node's AGSKMLViewPoint if possible.
    private func viewpoint(for node: AGSKMLNode) -> AGSViewpoint? {
        
        if let kmlViewpoint = node.viewpoint {
            // Convert the KML viewpoint to a viewpoint for the scene.
            // The KML viewpoint may not correspond to the node's geometry.
            
            switch kmlViewpoint.type{
            case .lookAt:
                var lookAtPoint = kmlViewpoint.location
                if kmlViewpoint.altitudeMode != .absolute{
                    // if the elevation is relative, account for the surface's elevation
                    let elevation = sceneSurfaceElevation(for: lookAtPoint) ?? 0
                    lookAtPoint = AGSPoint(x: lookAtPoint.x, y: lookAtPoint.y, z: lookAtPoint.z + elevation, spatialReference: lookAtPoint.spatialReference)
                }
                let camera = AGSCamera(lookAt: lookAtPoint,
                                       distance: kmlViewpoint.range,
                                       heading: kmlViewpoint.heading,
                                       pitch: kmlViewpoint.pitch,
                                       roll: kmlViewpoint.roll)
                // only the camera parameter is used by the scene
                return AGSViewpoint(center: kmlViewpoint.location, scale: 1, camera: camera)
            case .camera:
                // convert the KML viewpoint to a camera
                let camera = AGSCamera(location: kmlViewpoint.location,
                                       heading: kmlViewpoint.heading,
                                       pitch: kmlViewpoint.pitch,
                                       roll: kmlViewpoint.roll)
                // only the camera parameter is used by the scene
                return AGSViewpoint(center: kmlViewpoint.location, scale: 1, camera: camera)
            case .unknown:
                print("Unexpected AGSKMLViewpointType \(kmlViewpoint.type)")
                return nil
            }
        }
            // the node does not have a predefined viewpoint, so create a viewpoint based on its extent
        else if let extent = node.extent,
            // some nodes do not include a geometry, so check that the extent isn't empty
            !extent.isEmpty {
            
            var center = extent.center
            // take the scene's elevation into account
            let elevation = sceneSurfaceElevation(for: center) ?? 0
            
            // It's possible for `isEmpty` to be false but for width/height to still be zero.
            if extent.width == 0,
                extent.height == 0 {
                
                center = AGSPoint(x: center.x, y: center.y, z: center.z + elevation, spatialReference: extent.spatialReference)
                // Defaults based on Google Earth.
                let camera = AGSCamera(lookAt: center, distance: 1000, heading: 0, pitch: 45, roll: 0)
                // only the camera parameter is used by the scene
                return AGSViewpoint(targetExtent: extent, camera: camera)
                
            }
            else {
                // expand the extent to give some margins when framing the node
                let bufferRadius = max(extent.width, extent.height) / 20
                let bufferedExtent = AGSEnvelope(xMin: extent.xMin - bufferRadius,
                                                 yMin: extent.yMin - bufferRadius,
                                                 zMin: extent.zMin - bufferRadius + elevation,
                                                 xMax: extent.xMax + bufferRadius,
                                                 yMax: extent.yMax + bufferRadius,
                                                 zMax: extent.zMax + bufferRadius + elevation,
                                                 spatialReference: .wgs84())
                return AGSViewpoint(targetExtent: bufferedExtent)
            }
        }
        // the node doesn't have a predefined viewpoint or geometry
        return nil
    }
    
}
