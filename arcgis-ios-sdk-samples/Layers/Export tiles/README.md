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
3. Create default `AGSExportTileCacheParameters` for the task, specifying the area of interest, minimum scale and maximum scale.
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

ArcGIS tiled layers do not support reprojection, query, select, identify, or editing. Visit the [ArcGiS Online Developer's portal](https://developers.arcgis.com/ios/latest/swift/guide/layer-types-described.htm#ESRI_SECTION1_30E7379BE7FE4EC2AF7D8FBFEA7BB4CC) to learn more about the characteristics of ArcGIS tiled layers.

Refer to the [Tile Package Specification](https://github.com/Esri/tile-package-spec) on GitHub for more information on the tile package format.

## Tags

cache, download, offline
