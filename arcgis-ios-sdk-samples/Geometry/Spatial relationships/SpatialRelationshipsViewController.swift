//
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

class SpatialRelationshipsViewController: UIViewController, AGSGeoViewTouchDelegate, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var mapView: AGSMapView!
    private let graphicsOverlay = AGSGraphicsOverlay()

    let polygonGraphic: AGSGraphic = {
        //
        // Create an array of points that represents polygon. Use the same spatial reference as the underlying base map.
        let points = [
            AGSPoint(x: -5991501.677830, y: 5599295.131468, spatialReference: .webMercator()),
            AGSPoint(x: -6928550.398185, y: 2087936.739807, spatialReference: .webMercator()),
            AGSPoint(x: -3149463.800709, y: 1840803.011362, spatialReference: .webMercator()),
            AGSPoint(x: -1563689.043184, y: 3714900.452072, spatialReference: .webMercator()),
            AGSPoint(x: -3180355.516764, y: 5619889.608838, spatialReference: .webMercator())
        ]
        
        // Create a polygon from the array of points
        let polygon = AGSPolygon(points: points)
        
        // Create a outline symbol
        let outlineSymbol = AGSSimpleLineSymbol(style: .solid, color: .green, width: 2)
        
        // Create a fill symbol for polygon graphic
        let fillSymbol = AGSSimpleFillSymbol(style: .forwardDiagonal, color: .green, outline: outlineSymbol)
        
        // Create a graphic using the geometry and symbol
        let graphic = AGSGraphic(geometry: polygon, symbol: fillSymbol, attributes: nil)
        
        // Return graphic
        return graphic
    }()
    
    let polylineGraphic: AGSGraphic = {
        //
        // Create an array of points that represents polyline. Use the same spatial reference as the underlying base map.
        let points = [
            AGSPoint(x: -4354240.726880, y: -609939.795721, spatialReference: .webMercator()),
            AGSPoint(x: -3427489.245210, y: 2139422.933233, spatialReference: .webMercator()),
            AGSPoint(x: -2109442.693501, y: 4301843.057130, spatialReference: .webMercator()),
            AGSPoint(x: -1810822.771630, y: 7205664.366363, spatialReference: .webMercator())
        ]
        
        // Create a polyline from the array of points
        let polyline = AGSPolyline(points: points)
        
        // Create a line symbol
        let lineSymbol = AGSSimpleLineSymbol(style: .dash, color: .red, width: 4)
        
        // Create a graphic using the geometry and symbol
        let graphic = AGSGraphic(geometry: polyline, symbol: lineSymbol, attributes: nil)
        
        // Return graphic
        return graphic
    }()
    
    let pointGraphic: AGSGraphic = {
        //
        // Create a point. Use the same spatial reference as the underlying base map.
        let point = AGSPoint(x: -4487263.495911, y: 3699176.480377, spatialReference: .webMercator())
        
        // Create a marker symbol
        let markerSymbol = AGSSimpleMarkerSymbol(style: .circle, color: .blue, size: 10)
        
        // Create a graphic using the geometry and symbol
        let graphic = AGSGraphic(geometry: point, symbol: markerSymbol, attributes: nil)
        
        // Return graphic
        return graphic
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add the source code button item to the right of navigation bar
        (self.navigationItem.rightBarButtonItem as! SourceCodeBarButtonItem).filenames = ["SpatialRelationshipsViewController"]
        
        // Set the touch delegate
        mapView.touchDelegate = self
        
        // Instantiate map using basemap and set on mapView
        mapView.map = AGSMap(basemap: .topographic())

        // Add polygon, polyline and point graphics to graphics overlay
        graphicsOverlay.graphics.addObjects(from: [polygonGraphic, polylineGraphic, pointGraphic])
        
        // Set selection color of graphics overlay
        graphicsOverlay.selectionColor = .yellow
        
        // Add graphics overlay to mapView
        mapView.graphicsOverlays.add(graphicsOverlay)
        
        // Set viewpoint to the point graphic geometry
        if let point = pointGraphic.geometry as? AGSPoint {
            mapView.setViewpointCenter(point, scale: 100000000.0, completion: nil)
        }
    }
    
    // MARK: GeoView Touch Delegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //
        // Identify graphics overlay
        geoView.identify(graphicsOverlay, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 1) { [weak self]  (result) in
            //
            // Make sure self is around
            guard let strongSelf = self else {
                return
            }
            
            // Clear selection
            strongSelf.graphicsOverlay.clearSelection()
            
            // Make sure there is no error
            guard result.error == nil else {
                SVProgressHUD.showError(withStatus: result.error?.localizedDescription)
                return
            }
            
            // Return if there is no graphic identified or geometry is not available
            guard let identifiedGraphic = result.graphics.first, let selectedGeometry = identifiedGraphic.geometry else {
                return
            }
            
            // Select identified graphic
            identifiedGraphic.isSelected = true
            
            // Setup result view controller
            let storyboard = UIStoryboard(name: "ExpandableTableViewController", bundle: nil)
            let expandableTableViewController = storyboard.instantiateViewController(withIdentifier: "ExpandableTableViewController") as! ExpandableTableViewController
            
            // Check the geometry type and find it's
            // relationship with other geometries
            if let polylineGeometry = strongSelf.polylineGraphic.geometry, let polygonGeometry = strongSelf.polygonGraphic.geometry, selectedGeometry.geometryType == .point {
                //
                // Get the relationships with polyline and polygon
                let polylineRelationships = strongSelf.getSpatialRelationships(geometry1: selectedGeometry, geometry2: polylineGeometry)
                let polygonRelationships = strongSelf.getSpatialRelationships(geometry1: selectedGeometry, geometry2: polygonGeometry)
                
                // Add section for polyline relationships and it's items
                expandableTableViewController.sectionHeaderTitles.append("Relationship With Polyline")
                let polylineSectionItems = polylineRelationships.map { ($0, "") }
                expandableTableViewController.sectionItems.append(polylineSectionItems)
                
                // Add section for polygon relationships and it's items
                expandableTableViewController.sectionHeaderTitles.append("Relationship With Polygon")
                let polygonSectionItems = polygonRelationships.map { ($0, "") }
                expandableTableViewController.sectionItems.append(polygonSectionItems)
            }
            else if let pointGeometry = strongSelf.pointGraphic.geometry, let polygonGeometry = strongSelf.polygonGraphic.geometry, selectedGeometry.geometryType == .polyline {
                //
                // Get the relationships with point and polygon
                let pointRelationships = strongSelf.getSpatialRelationships(geometry1: selectedGeometry, geometry2: pointGeometry)
                let polygonRelationships = strongSelf.getSpatialRelationships(geometry1: selectedGeometry, geometry2: polygonGeometry)
                
                // Add section for point relationships and it's items
                expandableTableViewController.sectionHeaderTitles.append("Relationship With Point")
                let pointSectionItems = pointRelationships.map { ($0, "") }
                expandableTableViewController.sectionItems.append(pointSectionItems)
                
                // Add section for polygon relationships and it's items
                expandableTableViewController.sectionHeaderTitles.append("Relationship With Polygon")
                let polygonSectionItems = polygonRelationships.map { ($0, "") }
                expandableTableViewController.sectionItems.append(polygonSectionItems)
            }
            else if let pointGeometry = strongSelf.pointGraphic.geometry, let polylineGeometry = strongSelf.polylineGraphic.geometry, selectedGeometry.geometryType == .polygon {
                //
                // Get the relationships with point and polyline
                let pointRelationships = strongSelf.getSpatialRelationships(geometry1: selectedGeometry, geometry2: pointGeometry)
                let polylineRelationships = strongSelf.getSpatialRelationships(geometry1: selectedGeometry, geometry2: polylineGeometry)
                
                // Add section for point relationships and it's items
                expandableTableViewController.sectionHeaderTitles.append("Relationship With Point")
                let pointSectionItems = pointRelationships.map { ($0, "") }
                expandableTableViewController.sectionItems.append(pointSectionItems)
                
                // Add section for polyline relationships and it's items
                expandableTableViewController.sectionHeaderTitles.append("Relationship With Polyline")
                let polylineSectionItems = polylineRelationships.map { ($0, "") }
                expandableTableViewController.sectionItems.append(polylineSectionItems)
            }
            
            // Show the results
            expandableTableViewController.modalPresentationStyle = .popover
            expandableTableViewController.presentationController?.delegate = self
            expandableTableViewController.popoverPresentationController?.sourceView = strongSelf.mapView
            expandableTableViewController.popoverPresentationController?.sourceRect = CGRect(origin: screenPoint, size: .zero)
            expandableTableViewController.preferredContentSize = CGSize(width: 300, height: 200)
            strongSelf.present(expandableTableViewController, animated: true)
        }
    }
    
    // MARK: Helper Function
    
    /// This function checks the different relationships between
    /// two geometries and returns result as an array of strings
    ///
    /// - Parameters:
    ///   - geometry1: The input geometry to be compared
    ///   - geometry2: The input geometry to be compared
    /// - Returns: An array of strings representing relationship
    private func getSpatialRelationships(geometry1: AGSGeometry, geometry2: AGSGeometry) -> [String] {
        var relationships = [String]()
        if AGSGeometryEngine.geometry(geometry1, crossesGeometry: geometry2) { relationships.append("Crosses") }
        if AGSGeometryEngine.geometry(geometry1, contains: geometry2) { relationships.append("Contains") }
        if AGSGeometryEngine.geometry(geometry1, disjointTo: geometry2) { relationships.append("Disjoint") }
        if AGSGeometryEngine.geometry(geometry1, intersects: geometry2) { relationships.append("Intersects") }
        if AGSGeometryEngine.geometry(geometry1, overlapsGeometry: geometry2) { relationships.append("Overlaps") }
        if AGSGeometryEngine.geometry(geometry1, touchesGeometry: geometry2)  { relationships.append("Touches") }
        if AGSGeometryEngine.geometry(geometry1, within: geometry2) { relationships.append("Within") }
        return relationships
    }

    // MARK: UIPopoverPresentationControllerDelegate

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        //
        // Clear selection when popover is dismissed
        graphicsOverlay.clearSelection()
    }
}
