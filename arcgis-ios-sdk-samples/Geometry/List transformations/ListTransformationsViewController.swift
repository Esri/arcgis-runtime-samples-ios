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
    
    var datatumTransformations: [AGSDatumTransformation] = []
    var defaultTransformation: AGSDatumTransformation?
    let graphicsOverlay = AGSGraphicsOverlay()
    var originalGeometry = AGSPoint(x: 538985.355, y: 177329.516, spatialReference: AGSSpatialReference(wkid: 27700))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar.
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["ListTransformationsViewController"]

        // Get MapView from layout and set a map into this view
        mapView.map = AGSMap(basemap: AGSBasemap.lightGrayCanvasVector())
        mapView.graphicsOverlays.add(graphicsOverlay)
        
        //add original graphic to overlay
        addGraphic(originalGeometry, color: .red, style: .square)
        
        mapView.map?.load(completion: { [weak self] (error) in
            if error != nil {
                print("map load error = \(String(describing: error))")
                return
            }

            guard let originalGeometry = self?.originalGeometry else { return }
            self?.mapView.setViewpoint(AGSViewpoint(center: originalGeometry, scale: 5000), duration: 2.0, completion: nil)
            
            // set the url for our projection engine data;
            self?.setPEDataURL()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            datatumTransformations = AGSTransformationCatalog.transformationsBySuitability(withInputSpatialReference: inputSR, outputSpatialReference: outputSR, areaOfInterest: mapView.visibleArea?.extent)
        }
        else {
            datatumTransformations = AGSTransformationCatalog.transformationsBySuitability(withInputSpatialReference: inputSR, outputSpatialReference: outputSR)
        }
        
        defaultTransformation = AGSTransformationCatalog.transformation(forInputSpatialReference: inputSR, outputSpatialReference: outputSR)
        tableView.reloadData()
    }
    
    func setPEDataURL() {
        // find the PEDataRuntime folder from the documents directory
        // added using iTunes
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let subpaths = FileManager.default.subpaths(atPath: path[0])!
        
        // search for PEDataRuntime matches
        let predicate = NSPredicate(format: "SELF MATCHES %@", "PEDataRuntime")
        let peDataRuntimePaths = subpaths.filter({ (objc) -> Bool in
            return predicate.evaluate(with: objc)
        })

        // use first matching path as path to PE data
        if let documentPEDataRuntime = peDataRuntimePaths.first {
            // found "PEDataRuntime" folder, create full url
            let peDataURL = URL(fileURLWithPath: path[0]).appendingPathComponent(documentPEDataRuntime)
            try? AGSTransformationCatalog.setProjectionEngineDirectory(peDataURL)
        }
        
        setupTransformsList()
    }

    @IBAction func oderByMapExtentValueChanged(_ sender: Any) {
        setupTransformsList()
    }

    //MARK: - TableView data source

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datatumTransformations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DatumTransformCell", for: indexPath)

        // get the selected transformation
        let transformation = datatumTransformations[indexPath.row]

        // if we're missing the grid files, detail which ones
        var files = ""
        if transformation.isMissingProjectionEngineFiles {
            files = "Missing grid files"

            if let gt = transformation as? AGSGeographicTransformation {
                gt.steps.forEach { (step) in
                    if step.isMissingProjectionEngineFiles {
                        files.append(": " + step.projectionEngineFilenames.joined(separator: ","))
                    }
                }
            }
        }
        
        cell.textLabel?.text = transformation.name
        cell.detailTextLabel?.text = files
        
        if let defaultTransform = defaultTransformation {
            cell.isSelected = transformation.isEqual(to: defaultTransform)
        }
        else {
            cell.isSelected = false
        }
        
        return cell
    }
    
    //MARK: - TableView delegates
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let mapViewSR = mapView.spatialReference else { return }

        let selectedTransform = datatumTransformations[indexPath.row]
        if let projectedGeometry = AGSGeometryEngine.projectGeometry(originalGeometry, to: mapViewSR, datumTransformation: selectedTransform) {
            // projectGeometry succeeded
            if graphicsOverlay.graphics.count > 1,
                let graphics = graphicsOverlay.graphics as? [AGSGraphic],
                let graphic = (graphics).last {
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
