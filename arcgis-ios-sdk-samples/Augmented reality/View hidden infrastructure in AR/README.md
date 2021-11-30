# View hidden infrastructure in AR

Visualize hidden infrastructure in its real-world location using augmented reality.

![Add pipe infrastructure to the map](view-hidden-infrastructure-in-AR-1.png)
![View hidden infrastructure in AR](view-hidden-infrastructure-in-AR-2.png)

## Use case

You can use AR to "x-ray" the ground to see pipes, wiring, or other infrastructure that isn't otherwise visible. For example, you could use this feature to trace the flow of water through a building to help identify the source of a leak.

## How to use the sample

When the sample is launched, you'll see a map centered on your current location. Tap "Add" to launch the sketch editor and draw pipes around your location. After drawing the pipes, input an elevation value to place the drawn infrastructure above or below ground. When you're ready, tap the camera button to view the infrastructure you drew in AR.

There are two calibration modes in the sample: roaming and local. In roaming calibration mode, your position is updated automatically from the location data source every second. Because of that, you can only adjust heading, not position or elevation. This mode is best when working in a large area, where you would travel beyond the useful range of ARKit.

When you're ready to take a more precise look at the infrastructure, switch to local calibration mode. In local calibration mode, you can make fine adjustments to location, elevation, and heading to ensure the content is exactly where it should be.

## How it works

1. Draw pipes on the map. See more in the "Sketch on map" sample to learn how to use the sketch editor for creating graphics.
2. When you start the AR visualization experience, create and show the `ArcGISARView`.
3. Access the `sceneView` property of the AR View and set the space effect `none` and the atmosphere effect to `transparent`.
4. Create an elevation source and set it as the scene's base surface. Set the navigation constraint to `none` to allow going underground if needed.
5. Listen to ARKit events with `ARSCNViewDelegate`. Provide feedback on ARKit tracking as needed.
    * Note: ARKit feedback should only be provided when the location data source is not continuously updating, i.e. in "local" mode.
    * When the location is continuously being updated, ARKit tracking never has time to reach the "normal" state, so feedback is not useful.
6. Configure a graphics overlay and renderer for showing the drawn pipes. This sample uses an `AGSSolidStrokeSymbolLayer` with an `AGSMultilayerPolylineSymbol` to draw the pipes as tubes. Add the drawn pipes to the overlay.
7. Configure the calibration experience.
    * When in "roaming" (continuous location update) mode, only heading calibration should be enabled. In continuous update mode, the user's calibration is overwritten by sensor-based values every second.
    * When in "local" mode, the user needs to be able to adjust the heading, elevation, and position; position adjustment is achieved by panning.
    * This sample uses a basemap as a reference during calibration; consider how you will support your user's calibration efforts. A basemap-oriented approach won't work indoors or in areas without readily visible, unchanging features like roads.

## Relevant API

* AGSGraphicsOverlay
* AGSMultilayerPolylineSymbol
* AGSSketchEditor
* AGSSolidStrokeSymbolLayer
* AGSSurface
* ArcGISARView

## About the data

This sample uses Esri's [world elevation service](https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer) to ensure that the infrastructure you create is accurately placed beneath the ground.

Real-scale AR relies on having data in real-world locations near the user. It isn't practical to provide pre-made data like other Runtime samples, so you must draw your own nearby sample "pipe infrastructure" prior to starting the AR experience.

## Additional information

This sample requires a device that is compatible with ARKit.

Note that unlike other scene samples, a basemap isn't shown most of the time, because the real world provides the context. Only while calibrating is the basemap displayed at 50% opacity, to give the user a visual reference to compare to.

You may notice that pipes you draw underground appear to float more than you would expect. That floating is a normal result of the parallax effect that looks unnatural because you're not used to being able to see underground/obscured objects. Compare the behavior of underground pipes with equivalent pipes drawn above the surface - the behavior is the same, but probably feels more natural above ground because you see similar scenes day-to-day (e.g. utility wires).

**World-scale AR** is one of three main patterns for working with geographic information in augmented reality. Augmented reality is made possible with the ArcGIS Runtime Toolkit. See [Augmented reality](https://developers.arcgis.com/ios/scenes-3d/display-scenes-in-augmented-reality/) in the guide for more information about augmented reality and adding it to your app.

This sample uses a combination of two location data source modes: continuous update and one-time update, presented as "roaming" and "local" calibration modes in the app. The error in the position provided by ARKit increases as you move further from the origin, resulting in a poor experience when you move more than a few meters away. The location provided by GPS is more useful over large areas, but not good enough for a convincing AR experience on a small scale. With this sample, you can use "roaming" mode to maintain good enough accuracy for basic context while navigating a large area. When you want to see a more precise visualization, you can switch to "local" (ARKit-only) mode and manually calibrate for best results.

## Tags

augmented reality, full-scale, infrastructure, lines, mixed reality, pipes, real-scale, underground, visualization, visualize, world-scale
