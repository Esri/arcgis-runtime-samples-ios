# ArcGIS tiled layer (tile cache)

Load an offline copy of a tiled map service as a basemap.

![Tiled map of San Francisco](tiled-layer-tile-cache-1.png)
![List of tile packages](tiled-layer-tile-cache-2.png)

## Use case

Constructing an `ArcGISTiledLayer` from a local tile package (.tpk & .tpkx), allows you to use that basemap tiled service when the application is offline. Dividing a raster into tiles allows the map to provide relevant tiles and level of detail to the user when panning and zooming. For example, when working in an environment that has no connectivity, this could provide access to a map for navigating your surroundings.

## How to use the sample    

Launch the app to view the "San Francisco offline tile package" as the basemap. Tap the bottom button to get a list of tile packages available

## How it works

1. Create an `AGSTileCache`, specifying the path to the local tile package.
2. Create an `AGSArcGISTiledLayer` with the tile cache.
3. Create an `AGSBasemap` with the tiled layer.
4. Create an `AGSMap` with the basemap and set it to an `AGSMapView`.

## Relevant API

* AGSMap
* AGSArcGISTiledLayer
* AGSBasemap
* AGSTileCache

## Offline data

This sample uses the [San Francisco offline tile package](https://www.arcgis.com/home/item.html?id=72e703cd01654e7796eb1ae75af1cb53). It is downloaded from ArcGIS Online automatically.

## About the data

The map opens to a view of the city of San Francisco, CA. In a disconnected environment, this basemap tile service would be fully accessible to zoom and pan as if you were connected to a online service.

## Additional information

`AGSArcGISTiledLayer` and `AGSTileCache` supports both .tpk and .tpkx file formats.  

## Tags

cache, layers, offline, tile
