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

class ListTransformationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet var mapView: AGSMapView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var orderByMapExtent: UISwitch!
    
    var datumTransformations = [AGSDatumTransformation]()
    var defaultTransformation: AGSDatumTransformation?
    let graphicsOverlay = AGSGraphicsOverlay()
    var originalGeometry = AGSPoint(x: 538985.355, y: 177329.516, spatialReference: AGSSpatialReference(wkid: 27700))
    
    var projectedGraphic: AGSGraphic? {
        if graphicsOverlay.graphics.count > 1 {
            return graphicsOverlay.graphics.lastObject as? AGSGraphic
        } else {
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ListTransformationsViewController"]

        // Get MapView from layout and set a map into this view
        mapView.map = AGSMap(basemap: .lightGrayCanvasVector())
        mapView.graphicsOverlays.add(graphicsOverlay)
        
        //add original graphic to overlay
        addGraphic(originalGeometry, color: .red, style: .square)
        
        mapView.map?.load() { [weak self] (error) in
            if let error = error {
                print("map load error = \(error)")
            }
            else {
                self?.mapDidLoad()
            }
        }
    }
    
    func mapDidLoad() {
        mapView.setViewpoint(AGSViewpoint(center: originalGeometry, scale: 5000), duration: 2.0, completion: nil)
        
        // set the url for our projection engine data;
        setPEDataURL()
    }
    
    // add a graphic with the given geometry, color and style to the graphics overlay
    func addGraphic(_ geometry: AGSGeometry, color: UIColor, style: AGSSimpleMarkerSymbolStyle) {
        let sms = AGSSimpleMarkerSymbol(style: style, color: color, size: 15.0)
        graphicsOverlay.graphics.add(AGSGraphic(geometry: geometry, symbol: sms, attributes: nil))
    }
    
    // set up our datumTransformations array
    func setupTransformsList() {
        guard let map = mapView.map,
            let inputSR = originalGeometry.spatialReference,
            let outputSR = map.spatialReference else { return }
        
        // if orderByMapExtent is on, use the map extent when retrieving the transformations
        if orderByMapExtent.isOn {
            datumTransformations = AGSTransformationCatalog.transformationsBySuitability(withInputSpatialReference: inputSR, outputSpatialReference: outputSR, areaOfInterest: mapView.visibleArea?.extent)
        }
        else {
            datumTransformations = AGSTransformationCatalog.transformationsBySuitability(withInputSpatialReference: inputSR, outputSpatialReference: outputSR)
        }
        
        defaultTransformation = AGSTransformationCatalog.transformation(forInputSpatialReference: inputSR, outputSpatialReference: outputSR)

        // unselect selected row
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        
        // remove projected graphic from overlay
        if let graphic = projectedGraphic {
            // we have the projected graphic, remove it (it's always the last one)
            graphicsOverlay.graphics.remove(graphic)
        }
        
        tableView.reloadData()
    }
    
    func setPEDataURL() {
        if let projectionEngineDataURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("PEDataRuntime") {
            do {
                guard try projectionEngineDataURL.checkResourceIsReachable() else { return }
                
                // Normally, this method would be called immediately upon application startup before any other API method calls.
                // So usually it would be called from AppDelegate.application(_:didFinishLaunchingWithOptions:), but for the purposes
                // of this sample, we're calling it here.
                try AGSTransformationCatalog.setProjectionEngineDirectory(projectionEngineDataURL)
            } catch {
                print("Could not load projection engine data.  See the README file for instructions on adding PE data to your app.")
            }
        }
        
        setupTransformsList()
    }

    @IBAction func oderByMapExtentValueChanged(_ sender: Any) {
        setupTransformsList()
    }

    //MARK: - TableView data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datumTransformations.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DatumTransformCell", for: indexPath)
        // get the selected transformation
        let transformation = datumTransformations[indexPath.row]

        // disable selection if the transformation is missing files
        cell.isUserInteractionEnabled = !transformation.isMissingProjectionEngineFiles

        cell.textLabel?.text = transformation.name
        cell.detailTextLabel?.text = {
            if transformation.isMissingProjectionEngineFiles,
                // if we're missing the grid files, detail which ones
                let geographicTransformation = transformation as? AGSGeographicTransformation {
                let files = geographicTransformation.steps.flatMap { (step) -> [String] in
                    step.isMissingProjectionEngineFiles ? step.projectionEngineFilenames : []
                }
                return "Missing grid files: \(files.joined(separator: ", "))"
            } else {
                return ""
            }
        }()
        
        return cell
    }
    
    //MARK: - TableView delegates
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let mapViewSR = mapView.spatialReference else { return }

        let selectedTransform = datumTransformations[indexPath.row]
        if let projectedGeometry = AGSGeometryEngine.projectGeometry(originalGeometry, to: mapViewSR, datumTransformation: selectedTransform) {
            // projectGeometry succeeded
            if let graphic = projectedGraphic {
                // we've already added the projected graphic
                graphic.geometry = projectedGeometry
            }
            else {
                // add projected graphic
                addGraphic(projectedGeometry, color: .blue, style: .cross)
            }
        }
        else {
            // If a transformation is missing grid files, then it cannot be
            // successfully used to project a geometry, and "projectGeometry" will return nil.
            // In that case, remove projected graphic
            if graphicsOverlay.graphics.count > 1 {
                graphicsOverlay.graphics.removeLastObject()
            }
        }
    }
}
