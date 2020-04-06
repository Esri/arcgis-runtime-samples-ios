# Clip Geometry

Clip a geometry with another geometry.

![Image of clip geometry](clip-geometry.png.png)

## Use case

Create a new set of geometries for analysis (e.g. displaying buffer zones around abandoned coal mine shafts in an area of planned urban development) by clipping intersecting geometries.

## How to use the sample

Tap the button to clip the blue graphic with the red dashed envelopes.

## How it works

1.  Use the static method `class AGSGeometryEngine.clipGeometry(_:with:)` to generate a clipped `AGSGeometry`, passing in an existing `AGSGeometry` and an `AGSEnvelope` as parameters.  The existing geometry will be clipped where it intersects an envelope.
2.  Create a new `AGSGraphic` from the clipped geometry and add it to an `AGSGraphicsOverlay` on the `AGSMapView`.

## Relevant API

* class AGSGeometryEngine.clipGeometry(_:with:)
* AGSEnvelope
* AGSGeometry
* AGSGraphic
* AGSGraphicsOverlay

## Additional information

Note: the resulting geometry may be null if the envelope does not intersect the geometry being clipped.

## Tags

analysis, clip, geometry
