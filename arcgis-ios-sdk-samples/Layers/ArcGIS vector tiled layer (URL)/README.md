# ArcGIS vector tiled layer (URL)

Load an ArcGIS Vector Tiled Layer from a URL.

![ArcGIS vector tiled layer (URL) sample](vector-tiled-layer-url.png)

## Use case

Vector tile basemaps can be created in ArcGIS Pro and published as offline packages or online services. `ArcGISVectorTiledLayer` has many advantages over traditional raster based basemaps (`ArcGISTiledLayer`), including smooth scaling between different screen DPIs, smaller package sizes, and the ability to rotate symbols and labels dynamically.

## How to use the sample

Use the bottom button to load different vector tile basemaps.

## How it works

1. Create an `AGSArcGISVectorTiledLayer` with an ArcGIS Online service URL.
2. Add the layer as an `AGSBasemap` to the `AGSMap`.

## Relevant API

* AGSArcGISVectorTiledLayer
* AGSBasemap

## Tags

tiles, vector, vector basemap, vector tiled layer, vector tiles
