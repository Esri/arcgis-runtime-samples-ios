# Show custom callout

This sample demonstrates how to show mapview opened map and show location coordinates on a map using a callout.

## How to use the sample

Tap on the map to get the coordinates and closer look mapview for the location in a callout. Tap again to hide it.

![](image1.png)

## How it works

When the user taps on the map view the `geoView(_:didTapAtScreenPoint:mapPoint:)` method on the `AGSGeoViewTouchDelegate` is fired. Inside this method, we have the logic to either show or hide the callout. In order to show, we setup the `custom callout` object on the `mapView`, by setting the `closer mapview` property as "Location" and `detail` property as a string composed using `mapPoint`.






