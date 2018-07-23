# Distance Measurement Analysis
This sample demonstrates measuring 3D distances between two points in a scene.

The distance measurement analysis allows you to add the same measuring experience found in ArcGIS Pro, City Engine, and the ArcGIS API for JavaScript to your app. You can set the unit system of measurement (metric or imperial) and have the units automatically switch to one appropriate for the current scale. The rendering is handled internally so they do not interfere with other analyses like viewsheds.

![Image](image1.png)

## How to use the sample
Choose a unit system for the measurement in the segmented control. Long press any location in the scene to start measuring. Then drag to an end location, and lift your finger to complete the measure. Tap a new location to clear and start a new measurement.

## How it works
To measure distances with the `AGSLocationDistanceMeasurement` analysis:

1. Create an `AGSAnalysisOverlay` and add it to your scene view's analysis overlay collection: `sceneView.analysisOverlays.add(analysisOverlay)`.
2. Create a `AGSLocationDistanceMeasurement`, specifying the `startLocation` and `endLocation`. These can be the same point to start with. Add the analysis to the analysis overlay: `analysisOverlay.analyses.add(locationDistanceMeasurement)`. The measuring line will be drawn for you between the two points.
3. The `measurementChangedHandler` callback will fire if the distances change. You can get the new values for the `directDistance`, `horizontalDistance`, and `verticalDistance` from the parameters provided by the callback. The distance objects contain both the scalar value and unit of measurement.

## Relevant API  
- `AGSAnalysisOverlay`
- `AGSLocationDistanceMeasurement`

## Additional information
The `AGSLocationDistanceMeasurement` analysis only performs planar distance calculations. This may not be appropriate for large distances where the Earth's curvature needs to be taken into account.

## Tags
Analysis, 3D
