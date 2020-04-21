# Distance Measurement Analysis

Measure distances between two points in 3D.

![Distance Measurement Analysis](distance-measurement.png)

## Use case

The distance measurement analysis allows you to add to your app the same interactive measuring experience found in ArcGIS Pro, City Engine, and the ArcGIS API for JavaScript. You can set the unit system of measurement (metric or imperial). The units automatically switch to one appropriate for the current scale.

## How to use the sample

Choose a unit system for the measurement in the segmented control. Long press any location in the scene to start measuring. Then drag to an end location, and lift your finger to complete the measure. Tap a new location to clear and start a new measurement.

## How it works

1. Create an `AGSAnalysisOverlay` object and add it to the analysis overlay collection of the `AGSSceneView` object.
2. Specify the start location and end location to create an `AGSLocationDistanceMeasurement` object. Initially, the start and end locations can be the same point.
3. Add the location distance measurement analysis to the analysis overlay.
4. The `measurementChangedHandler` callback will fire if the distances change. You can get the new values for the `directDistance`, `horizontalDistance`, and `verticalDistance` from the parameters provided by the callback. The distance objects contain both the scalar value and unit of measurement.

## Relevant API

* AGSAnalysisOverlay
* AGSLocationDistanceMeasurement
* AGSMeasurementChangedEvent

## Additional information

The `AGSLocationDistanceMeasurement` analysis only performs planar distance calculations. This may not be appropriate for large distances where the Earth's curvature must be considered.

## Tags

3D, analysis, distance, measure
