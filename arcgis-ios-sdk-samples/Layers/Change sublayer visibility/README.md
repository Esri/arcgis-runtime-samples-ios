# Change sublayer visibility

Change the visibility of sublayers.

![All sublayers visible](change-sublayer-visibility-1.png)
![Cities sublayer hidden](change-sublayer-visibility-2.png))

## Use case

A map image layer may contain many sublayers such as different types of roads in a road network or city, county, and state borders in a US map. The user may only be interested in a subset of these sublayers. Or, perhaps showing all of the sublayers would show too much detail. In these cases, you can hide certain sublayers by changing their visibility.

## How to use the sample

Tap the bottom button to display a list of sublayers. Tap the switches to toggle the visibility of the sublayers.

## How it works

1.  Create an `AGSArcGISMapImageLayer` object with the URL to a map image service.
2.  Get all of the map image layer's `AGSArcGISMapImageSublayer`s.
3.  For each layer in the sublayer list, set its visible property to true or false.

## Relevant API

* AGSArcGISMapImageLayer
* AGSArcGISMapImageSublayer

## Tags

layer, sublayer, visibility
