# ArcGIS tiled layer (URL)

Load an ArcGIS Vector Tiled Layer from a URL.

![ArcGIS tiled layer (URL) sample](tiled-layer-url.png)

## Use case

Vector tile basemaps can be created in ArcGIS Pro and published as offline packages or online services. `AGSArcGISVectorTiledLayer` has many advantages over traditional raster based basemaps (`AGSArcGISTiledLayer`), including smooth scaling between different screen DPIs, smaller package sizes, and the ability to rotate symbols and labels dynamically.

## How to use the sample

Pan and zoom to explore the vector tile basemap.

## How it works

1. Construct an `AGSArcGISVectorTiledLayer` with an ArcGIS Online service URL.
2. Add the layer instance to the map's `operationalLayers` array.

## Relevant API

* ArcGISVectorTiledLayer
* AGSMap

## Tags

tiles, vector, vector basemap, vector tiled layer, vector tiles
