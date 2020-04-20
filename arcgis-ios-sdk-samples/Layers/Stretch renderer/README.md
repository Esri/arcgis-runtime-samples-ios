# Stretch renderer

This sample demonstrates how to use stretch renderer on a raster layer.

## How to use the sample

Tap the `Edit Renderer` button in the toolbar to open the settings for the stretch renderer. As you change the stretch type, the min, and the max, the raster layer will update accordingly.

![Default stretch renderer](stretch-renderer-1.png)
![Edited stretch renderer ](stretch-renderer-2.png)


## Use case

An appropriate stretch renderer can enhance the contrast of raster imagery, allowing the user to control how their data is displayed for efficient imagery analysis.

## How to use the sample

Tap the toolbar button to change any of the following properties.

* AGSStandard deviation - a linear stretch defined by the standard deviation of the pixel values
* AGSMin-max - a linear stretch based on minimum and maximum pixel values
* AGSPercent clip - a linear stretch between the defined percent clip minimum and percent clip maximum pixel values

## How it works

1. Create an `AGSRaster` from a raster file.
2. Create an `AGSRasterLayer` from the `AGSRaster`.
3. Add the layer to the map.
4. Create an `AGSStretchRenderer`, specifying the `AGSStretchParameters` and other properties.
5. Apply the `AGSStretchRenderer` to the raster layer.

## Relevant API

* AGSColorRamp
* AGSMinMaxStretchParameters
* AGSPercentClipStretchParameters
* AGSRaster
* AGSRasterLayer
* AGSStandardDeviationStretchParameters
* AGSStretchParameters
* AGSStretchRenderer

## Offline data

This sample uses a [raster file](https://arcgisruntime.maps.arcgis.com/home/item.html?id=95392f99970d4a71bd25951beb34a508). It is downloaded from ArcGIS Online automatically.

## About the data

The raster used in this sample shows an area in the south of the Shasta-Trinity National Forest, California.

## Additional information

See [Stretch function](http://desktop.arcgis.com/en/arcmap/latest/manage-data/raster-and-images/stretch-function.htm) in the *ArcMap* AGSdocumentation for more information about the types of stretches that can be performed.

## Tags

analysis, deviation, histogram, imagery, interpretation, min-max, percent clip, pixel, raster, stretch, symbology, visualization
