# Min max scale

Restrict zooming between specific scale ranges.

![Image of min max scale](min-max-scale.png)

## Use case

Data may only appear at a certain scale on a map, and may be visually lost if zooming too far in or out. Setting the minimum and maximum scales ensures the zoom extents are appropriately limited for the purposes of the map.

## How to use the sample

Zoom in and out of the map. The zoom extents of the map are limited between the given minimum and maximum scales.

## How it works

1. Instantiate an `AGSMap` object.
2. Set the minimum and maximum scale using the `minScale` and `maxScale` properties of `AGSMap`.
3. Set the map to an `AGSMapView` object.
 
## Relevant API

* AGSMap
* AGSMapView
* AGSViewpoint

## Tags

area of interest, level of detail, maximum, minimum, scale, viewpoint
