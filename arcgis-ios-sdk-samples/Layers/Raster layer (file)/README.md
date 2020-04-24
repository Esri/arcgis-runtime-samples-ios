# Raster layer (file)

Create and use a raster layer made from a local raster file.

![Raster layer (file) sample](raster-layer-file.png)

## Use case

Rasters can be digital aerial photographs, imagery from satellites, digital pictures, or even scanned maps. An end-user will frequently need to import raster files acquired through various data-collection methods into their map to view and analyze the data.

## How to use the sample

When the sample starts, a raster will be loaded from a file and displayed in the map view.

## How it works

1. Create an `AGSRaster` from a raster file.
2. Create an `AGSRasterLayer` from the raster.
3. Add it to the map's array of `operationalLayers`.

## Relevant API

* AGSRaster
* AGSRasterLayer

## Additional information

See the topic [What is raster data?](https://desktop.arcgis.com/en/arcmap/10.3/manage-data/raster-and-images/what-is-raster-data.htm) in the *ArcMap* documentation for more information about raster images.

## Tags

data, image, import, layer, raster, visualization
