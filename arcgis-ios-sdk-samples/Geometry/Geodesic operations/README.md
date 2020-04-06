# Geodesic operations

Calculate a geodesic path between two points and measure its distance.

![Image of geodesic operations](geodesic-operations.png)

## Use case

A geodesic distance provides an accurate, real-world distance between two points. Visualizing flight paths between cities is a common example of a geodesic operation since the flight path between two airports takes into account the curvature of the earth, rather than following the planar path between those points, which appears as a straight line on a projected map.

## How to use the sample

Tap anywhere on the map. A line graphic will display the geodesic line between the two points. In addition, text that indicates the geodesic distance between the two points will be updated. Tap elsewhere and a new line will be created.

## How it works

1. Create an `AGSPoint` in New York City and display it as an `AGSGraphic`.
2. Obtain a new point when a tap occurs on the `AGSMapView` and add this point as a graphic.
3. Create an `AGSPolyline` from the two points.
4. Execute `class AGSGeometryEngine.geodeticDensifyGeometry(_:maxSegmentLength:lengthUnit:curveType:)` by passing in the created polyline, then create a graphic from the returned `AGSGeometry`.
5. Execute `class AGSGeometryEngine.geodeticLength(of:lengthUnit:curveType:)` by passing in the two points and display the returned length on the screen.

## Relevant API

* class AGSGeometryEngine.geodeticDensifyGeometry(_:maxSegmentLength:lengthUnit:curveType:)
* class AGSGeometryEngine.geodeticLength(of:lengthUnit:curveType:)

## About the data

The Imagery basemap provides the global context for the displayed geodesic line.

## Tags

densify, distance, geodesic, geodetic
