# Display scenes in tabletop AR

Use augmented reality (AR) to pin a scene to a table or desk for easy exploration.

![Scene content shown sitting on a surface, as if it were a 3D printed model](image1.png)

## Use case

Tabletop scenes allow you to use your device to interact with scenes as if they are 3D-printed model models sitting on your desk. You could use this to virtually explore a proposed development without needing to create a physical model.

## How to use the sample

You'll see a feed from the camera when you open the sample. Tap on any flat, horizontal surface (like a desk or table) to place the scene. With the scene placed, you can move the camera around the scene to explore. You can also pan and zoom with touch to adjust the position of the scene.

## How it works

1. Create an `ArcGISARView` and add it to the view.
    * Note: this sample uses content in the WGS 84 geographic tiling scheme, rather than the web mercator tiling scheme. Once a scene has been displayed, the scene view cannot display another scene with a non-matching tiling scheme. To avoid that, the sample starts by showing a blank scene with an invisible base surface. Touch events will not be raised for the scene view unless a scene is displayed.
2. Listen for ARKit tracking state updates with `arView.arSCNViewDelegate` and provide feedback to the user as necessary.
3. When tracking is ready, wait for the user to tap, then use `arView.setInitialTransformation(using: screenPoint)` to set the initial transformation, which allows you to place the scene. This method uses ARKit's built-in plane detection.
4. Create and display the scene. To allow you to look at the content from below, set the base surface navigation constraint to `none`.
5. To create a realistic tabletop mapping experience, set the scene's base surface opacity to 0. This will ensure that only the target scene content is visible.
6. For tabletop mapping, the arView's `originCamera` must be set such that the altitude of the camera matches the altitude of the lowest point in the scene. Otherwise, scene content will float above or below the targeted anchor position identified by the user. For this sample, the origin camera's latitude and longitude are set to the center of the scene for best results. This will give the impression that the scene is centered on the location the user tapped.
7. Set the `translationFactor` on the scene view such that the user can view the entire scene by moving the device around it. The translation factor defines how far the virtual camera moves when the physical camera moves.
    * A good formula for determining translation factor to use in a tabletop map experience is **translationFactor = sceneWidth / tableTopWidth**. The scene width is the width/length of the scene content you wish to display in meters. The tabletop width is the length of the area on the physical surface that you want the scene content to fill. For simplicity, the sample assumes a scene width of 800 meters.

## Relevant API

* ArcGISARView
* AGSSceneView

## Offline data

This sample uses offline data, available as an [item on ArcGIS Online](https://www.arcgis.com/home/item.html?id=7dd2f97bb007466ea939160d0de96a9d).

## About the data

This sample uses the [Philadelphia Mobile Scene Package](https://www.arcgis.com/home/item.html?id=7dd2f97bb007466ea939160d0de96a9d). It was chosen because it is a compact scene ideal for tabletop use. Note that tabletop mapping experiences work best with small, focused scenes. The small, focused area with basemap tiles defines a clear boundary for the scene.

## Additional information

This sample requires a device that is compatible with ARKit 1.0 on iOS.

**Tabletop AR** is one of three main patterns for working with geographic information in augmented reality. See [Display scenes in augmented reality](https://developers.arcgis.com/ios/latest/swift/guide/display-scenes-in-augmented-reality.htm) in the guide for more information.

This sample uses the ArcGIS Runtime Toolkit. See [Augmented reality]() in the guide to learn about the toolkit and how to add it to your app.

## Tags

augmented reality, drop, mixed reality, model, pin, place, table-top, tabletop
