# Create terrain surface from a local tile package

Set the terrain surface with elevation described by a local tile package.

![Create terrain from a local tile package](create-terrain-from-a-local-tile-package.png)

## Use case

In a scene view, the terrain surface is what the basemap, operational layers, and graphics are draped onto. For example, when viewing a scene in a mountainous region, applying a terrain surface to the scene will help in recognizing the slopes, valleys, and elevated areas.

## How to use the sample

When loaded, the sample will show a scene with a terrain surface applied. Pan and zoom to explore the scene and observe how the terrain surface allows visualizing elevation differences.

## How it works

1. Create an `AGScene` and add it to a `AGSSceneView`.
2. Create an `AGSArcGISTiledElevationSource` with the path to the local tile package.
3. Add this source to the scene's base surface.

## Relevant API

* AGSArcGISTiledElevationSource
* AGSSurface

## Offline data

This sample uses the [Monterey Elevation](https://arcgisruntime.maps.arcgis.com/home/item.html?id=52ca74b4ba8042b78b3c653696f34a9c) tile package, using CompactV2 storage format (.tpkx). It is downloaded from ArcGIS Online automatically.

## About the data

This terrain data comes from Monterey, California.

## Additional information

The tile package must be a LERC (limited error raster compression) encoded TPKX. Details on the topic can be found in [Share a tile package](https://pro.arcgis.com/en/pro-app/help/sharing/overview/tile-package.htm) in the *ArcGIS Pro* documentation.

## Tags

3D, elevation, surface, tile cache
