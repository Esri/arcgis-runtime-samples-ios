# Show callout

Show a callout with the latitude and longitude of user-tapped points.

![Image of show callout](show-callout.jpg)

## Use case

Callouts are used to display temporary detail content on a map. You can display text and arbitrary UI controls in callouts.

## How to use the sample

Tap anywhere on the map. A callout showing the WGS84 coordinates for the tapped point will appear. Tap again to hide it.

## How it works

1. Use `AGSGeoViewTouchDelegate.geoView(_:didTapAtScreenPoint:mapPoint:)` to get the `mapPoint` where a user tapped on the map.
4. Create a string to display the coordinates; note that latitude and longitude in WGS84 map to the Y and X coordinates.
5. Create a new callout definition using a title string as `title` and the coordinate string as `detail`.
6. Display the callout by calling `AGSCallout.show(at:screenOffset:rotateOffsetWithMap:animated:)` on the map view with the location and the callout definition.

## Relevant API

* AGSCallout
* AGSGeoViewTouchDelegate

## Tags

balloon, bubble, callout, flyout, flyover, info window, popup, tap
