# Spatial relationships

Determine spatial relationships between two geometries.

![Image of spatial relationships](spatial-relationships.png)

## Use case

In case of a natural disaster, emergency services can represent the affected areas using polygons. By determining the spatial relationships between these and any other existing features such as populated areas, infrastructure, or natural resources, it is possible to quickly determine which of the existing features might be affected or is in further danger, helping to assess risk and define further action.

## How to use the sample

Tap on the map to select one of the three graphics, and its geometry will be used to check the spatial relationships with other graphics geometries. The result will be displayed in the popover.

## How it works

1. Get the geometry from two different graphics. In this example the geometry of the selected graphic is compared to the geometry of each unselected graphic.
2. Use the methods in `AGSGeometryEngine` - `geometry(_:crossesGeometry:)`, `geometry(_:contains:)`, `geometry(_:disjointTo:)`, `geometry(_:intersects:)`, `geometry(_:overlapsGeometry:)`, `geometry(_:touchesGeometry:)` and `geometry(_:within:)`, to check the relationship between the geometries, e.g. `contains`, `disjoint`, `intersects`, etc. If the method returns `true`, the relationship exists.

## Relevant API

* class AGSGeometryEngine.geometry(_:contains:)
* class AGSGeometryEngine.geometry(_:crossesGeometry:)
* class AGSGeometryEngine.geometry(_:disjointTo:)
* class AGSGeometryEngine.geometry(_:intersects:)
* class AGSGeometryEngine.geometry(_:overlapsGeometry:)
* class AGSGeometryEngine.geometry(_:touchesGeometry:)
* class AGSGeometryEngine.geometry(_:within:)
* AGSGeometry
* AGSGeometryEngine
* AGSGeometryType
* AGSGraphic
* AGSPoint
* AGSPolygon
* AGSPolyline

## Tags

geometries, relationship, spatial analysis
