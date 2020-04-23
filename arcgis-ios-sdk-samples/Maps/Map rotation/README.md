# Map rotation

Rotate a map.

![Image of map rotation](map-rotation.png)

## Use case

A user may wish to view the map in an orientation other than north-facing.

## How to use the sample

Use the slider or pinch to rotate the map. If the map is not pointed north, the compass will display the current heading. Tap the compass to set the map's heading to north.

## How it works

1. Instantiate an `AGSMap` object.
2. Set the map to an `AGSMapView` object.
3. Use the `AGSMapView.setViewpointRotation(_:completion:)` method to change the rotation angle.

## Relevant API

* AGSMap
* AGSMapView

## Tags

rotate, rotation, viewpoint
