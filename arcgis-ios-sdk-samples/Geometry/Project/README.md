# Project

Project a point to another spatial reference.

Being able to project between spatial references is fundamental to a GIS. An example of when you would need to re-project data is if you had data in two different spatial references, but wanted to perform an intersect analysis with the `AGSGeometryEngine.Intersection` method. This method takes two geometries as parameters, and both geometries must be in the same spatial reference. If they are not, you could first use `AGSGeometryEngine.project` to convert the geometries so they match.

![Project App](project.png)

## How to use the sample

Tap anywhere on the map. A callout will display the tapped location's coordinate in the original (basemap's) spatial reference and in the projected spatial reference.

## How it works

To project a geometry to another spatial reference: Use the `AGSGeometryEngine.projectGeometry` method, passing in the chosen coordinates to find the spatial reference coordinates. 

## Relevant API

* AGSGeometryEngine
* AGSPoint
* AGSSpatialReference

## Tags

AGSGeometryEngine, AGSSpatialReference
