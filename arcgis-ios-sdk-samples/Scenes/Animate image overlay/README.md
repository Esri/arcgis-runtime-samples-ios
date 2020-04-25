# Animate images with image overlay

Animate a series of images with an image overlay.

![Image of animate images with image overlay](animate-images-with-image-overlay.png)

## Use case

An image overlay is useful for displaying fast and dynamic images; for example, rendering real-time sensor data captured from a drone. Each frame from the drone becomes a static image which is updated on the fly as the data is made available.

## How to use the sample

The sample loads a map of the Southwestern United States. Tap the "Play" or "Pause" buttons to start or pause the radar animation. Select a frame rate to decide how quickly the animation plays. Move the slider to change the opacity of the image overlay.

## How it works

1. Create an `AGSImageOverlay` and add it to the `AGSSceneView`.
2. Set up a timer with an initial frame rate of 60 FPS.
3. Create a new `AGSImageFrame` object every time interval, and set it on the image overlay.

## Relevant API

* AGSImageFrame
* AGSImageOverlay
* AGSSceneView

## About the data

These radar images were captured by the US National Weather Service (NWS). They highlight the Pacific Southwest sector which is made up of part the western United States and Mexico. For more information visit the [National Weather Service](https://www.weather.gov/jetstream/gis) website. The archive for radar images can be downloaded from [ArcGIS Online](https://runtime.maps.arcgis.com/home/item.html?id=9465e8c02b294c69bdb42de056a23ab1).

## Additional information

The supported image formats are GeoTIFF, TIFF, JPEG, and PNG. `AGSImageOverlay` does not support the rich processing and rendering capabilities of an `AGSRasterLayer`. Use `AGSRaster` and `AGSRasterLayer` for static image rendering, analysis, and persistence.

## Tags

3D, animation, drone, dynamic, image frame, image overlay, real time, rendering
