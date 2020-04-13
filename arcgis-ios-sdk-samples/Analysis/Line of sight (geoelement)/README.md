# Line of sight (geoelement)

Show a line of sight between two moving objects.

![Line of sight (geoelement)](line-of-sight-geoelement.png)

## Use case

A line of sight between `GeoElement`s (i.e. observer and target) will not remain constant whilst one or both are on the move. An `AGSGeoElementLineOfSight` is therefore useful in cases where visibility between two `AGSGeoElement`s requires monitoring over a period of time in a partially obstructed field of view
(such as buildings in a city).

## How to use the sample

A line of sight will display between a point on the Empire State Building (observer) and a taxi (target).
The taxi will drive around a block and the line of sight should automatically update.
The taxi will be highlighted when it is visible. You can change the observer height with the slider to see how it affects the target's visibility.

## How it works

1. Instantiate an `AGSAnalysisOverlay` and add it to the `AGSSceneView`'s analysis overlays collection.
2. Instantiate an `AGSGeoElementLineOfSight`, passing in observer and target `AGSGeoElement`s (features or graphics). Add the line of sight to the analysis overlay's analyses collection.
3. To get the target visibility when it changes, observe the target visibility changing on the `AGSGeoElementLineOfSight` instance.

## Relevant API

* AGSAnalysisOverlay
* AGSGeoElementLineOfSight
* AGSLineOfSight.targetVisibility

## Offline data

This sample uses the [Taxi](https://www.arcgis.com/home/item.html?id=3af5cfec0fd24dac8d88aea679027cb9) CAD Drawing. It is downloaded from ArcGIS Online automatically.
## Tags

3D, line of sight, visibility, visibility analysis
