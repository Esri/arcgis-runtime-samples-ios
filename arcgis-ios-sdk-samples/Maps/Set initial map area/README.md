# Map initial extent

Display the map at an initial viewpoint representing a bounding geometry.

![Image of map initial extent](map-initial-extent.png)

## Use case

Setting the initial viewpoint is useful when a user wishes to first load the map at a particular area of interest. 

## How to use the sample

As application is loading, initial view point is set and map view opens at the given location.

## How it works

1. Instantiate an `AGSMap` object.
2. Instantiate an `AGSViewpoint` object using an `AGSEnvelope` object.
3. Set the starting location to the `initialViewpoint` property of the map.
4. Set the map to an `AGSMapView` object.
 
## Relevant API

* AGSMap
* AGSEnvelope
* AGSMapView
* AGSViewpoint

## Tags

initial viewpoint, extent, zoom, envelope
