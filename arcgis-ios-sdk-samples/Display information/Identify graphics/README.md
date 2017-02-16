#Identify graphics

This sample demonstrates how to identify graphics in a graphics overlay

##How to use the sample

When you tap on a graphic on the map, you should see an alert

![](image1.png)

##How it works

It requires the `geoView(_:didTapAtScreenPoint:mapPoint:)` method on `AGSGeoViewTouchDelegate` to know when a user tapped on the map. The method provides a property `mapPoint` which specifies the corresponding touch location in the map. The app then uses the `identify(_:screenPoint:tolerance:returnPopupsOnly:maximumResults:completion:)` method on `AGSMapView` to identify graphics at that particular touch location.

Related: `identifyGraphicsOverlays(atScreenPoint:tolerance:returnPopupsOnly:maximumResultsPerOverlay:completion:)`



