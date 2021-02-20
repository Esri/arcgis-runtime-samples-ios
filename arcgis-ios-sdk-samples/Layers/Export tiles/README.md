# Export tiles

Download tiles to a local tile cache file stored on the device.

![Map of tiles to export](export-tiles-1.png)
![Tile package result](export-tiles-2.png)

## Use case

Field workers with limited network connectivity can use exported tiles as a basemap for use offline.

## How to use the sample

Pan and zoom into the desired area, making sure the area is within the red boundary. Tap the "Export tiles" button and choose an export format to start the process. On successful completion, you will see a preview of the downloaded tile package.

## How it works

1. Create a map and set its `minScale` to 10,000,000. Limiting the scale in this sample limits the potential size of the selection area, thereby keeping the exported tile package to a reasonable size.
2. Create an `AGSExportTileCacheTask`, passing in the URL of the tiled layer.
3. Create default `AGSExportTileCacheParameters` for the task, specifying the area of interest, minimum scale, and maximum scale.
4. Use the parameters and a path to create an `AGSExportTileCacheJob` from the task.
5. Start the job, and when it completes successfully, get the resulting `AGSTileCache`.
6. Use the tile cache to create an `AGSArcGISTiledLayer` and display it in the map.

## Relevant API

* AGSArcGISTiledLayer
* AGSExportTileCacheJob
* AGSExportTileCacheParameters
* AGSExportTileCacheTask
* AGSTileCache

## Additional information

ArcGIS tiled layers do not support reprojection, query, select, identify, or editing. See the [layer types](https://developers.arcgis.com/ios/layers/#layer-types) discussion in the developers guide to learn more about the characteristics of ArcGIS tiled layers.

The sample first tries to export the tiles using the CompactV2 (.tpkx) format. If it isn't supported, it will fallback to the CompactV1 (.tpk) format. Refer to the [Tile Package Specification](https://github.com/Esri/tile-package-spec) on GitHub for more information on the tile package format.

This workflow can be used with [Esri basemaps](https://www.esri.com/en-us/arcgis/products/location-services/services/basemaps).

## Tags

cache, download, offline
