# Densify and generalize 
Demonstrates how to densify or generalize a polyline geometry. In this example, points representing a ship's location are shown at irregular intervals. One can densify the polyline connecting these lines to interpolate points along the line at regular intervals. Generalizing the polyline can also simplify the geometry while preserving its general shape.

![](image1.png)

## How to use the sample 
Tap "Options" to open the settings for the densify and generalize methods. You can toggle the switches for either method to add or remove its effect from the results. Move the sliders to update the parameter values.

## How it works
To densify and generalize a polyline 
1. Use the static method `class AGSGeometryEngine.densifyGeometry(_:maxSegmentLength:)` to densify the polyline . The resulting polyline will add points along the line so that there are no points greater than `maxSegmentLength` from the next point.
2. Use the static method `class AGSGeometryEngine.generalizeGeometry(_:maxDeviation:removeDegenerateParts:)` to generalize the polyline. The resulting polyline will have points or shifted from the line to simplify the shape. None of these points can deviate farther from the original line than `maxDeviation`. The last parameter, `removeDegenerateParts` , will clean up extraneous parts if the geometry is multi-part. It will have no effect in this sample.
3. Note that `maxSegmentLength` and `maxDeviation` are in the units of geometry's coordinate system. This could be in degrees in some coordinate systems. In this example, a cartesian coordinate system is used and at a small enough scale that geodesic distances are not required.

## Relevant API
* `AGSMap`
* `AGSBasemap`
* `AGSGeometryEngine`
* `AGSGraphic`
* `AGsGraphicsOverlay`
* `AGSMapView`
* `AGSMultipoint`
* `AGSPointCollection`
* `AGSPolyline`
* `AGSSimpleLineSymbol`
* `AGSSimpleMarkerSymbol`
* `AGSSpatialReference`

## Tags
Edit and Manage Data