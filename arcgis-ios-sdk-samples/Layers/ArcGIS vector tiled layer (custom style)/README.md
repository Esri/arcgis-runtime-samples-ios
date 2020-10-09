# ArcGIS vector tiled layer (custom style)

Load ArcGIS vector tiled layers using custom styles.

![Custom styled ArcGIS vector tiled layer](vector-tiled-layer-custom-1.png)
![Offline custom style](vector-tiled-layer-custom-2.png)

## Use case

Vector tile basemaps can be created in ArcGIS Pro and published as offline packages or online services. You can create a custom style tailored to your needs and easily apply them to your map. `AGSArcGISVectorTiledLayer` has many advantages over traditional raster based basemaps (`AGSArcGISTiledLayer`), including smooth scaling between different screen DPIs, smaller package sizes, and the ability to rotate symbols and labels dynamically.

## How to use the sample

Pan and zoom to explore the vector tile basemap.

## How it works

1. Construct an `AGSArcGISVectorTiledLayer` with the URL of a custom style from AGOL.
    * Follow these steps to create a vector tiled layer with a custom style from offline resources:
    1. Construct an `AGSVectorTileCache` using the name of the local vector tile package.
    2. Create an `AGSPortalItem` using the URL of a custom style.
    3. Create an `AGSExportVectorTilesTask` using the portal item.
    4. Get the `AGSExportVectorTilesJob` using `AGSExportVectorTilesTask.exportStyleResourceCacheJob(withDownloadDirectory:)`.
    5. Start the job using `AGSExportVectorTilesJob.start(statusHandler:completion:)`.
    6. Once the job is complete, construct an `AGSArcGISVectorTiledLayer` using the vector tile cache and the `AGSItemResourceCache` from the job's result.
2. Create an `AGSBasemap` from the `AGSArcGISVectorTiledLayer`.
3. Assign the `AGSBasemap` to the map's `basemap`.

## Relevant API

* AGSArcGISVectorTiledLayer
* AGSExportVectorTilesTask
* AGSItemResourceCache
* AGSMap
* AGSVectorTileCache

## Tags

tiles, vector, vector basemap, vector tiled layer, vector tiles
