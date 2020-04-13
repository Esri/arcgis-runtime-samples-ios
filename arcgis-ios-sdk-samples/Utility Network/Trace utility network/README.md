# Find connected features in utility networks

Find all features connected to a set of starting points in a utility network.

![](image1.png)

## Use case

This is useful to visualize and validate the network topology of a utility network for quality assurance. 

## How to use the sample

To add a starting point, select 'Start' and tap on one or more features. To add a barrier, select 'Barrier' and tap on one or more features. Depending on the type of feature, you may be prompted to select a terminal or the distance from the tapped location will be computed. Tap 'Trace' to highlight all features connected to the specified starting locations and not positioned beyond the barriers. Tap 'Reset' to clear parameters and start over.

## How it works

1. Create an `AGSMapView` and listen for `didTap` events on the `AGSGeoViewTouchDelegate`.
2. Create an `AGSMap` that contains `AGSFeatureLayer`(s) that are part of a utility network.
3. Create and load an `AGSUtilityNetwork` with the same feature service URL and map.
4. Add an `AGSGraphicsOverlay` with symbology that distinguishes starting points from barriers.
5. Identify tapped features on the map and add an `AGSGraphic` that represents its purpose (starting point or barrier) at the location of each identified feature.
6. Determine the type of the identified feature using `AGSUtilityNetwork.definition.networkSource` passing its table name.
7. If the type is a junction, display a terminal picker when more than one terminal is found and create an `AGSUtilityElement` using the selected terminal, or the single terminal if there is only one.
8. If the type is an edge, create a `AGSUtilityElement` from the identified feature and compute how far along the edge the user tapped using `AGSGeometryEngine.fractionAlongLine()`.
9. Run `AGSUtilityNetwork.trace()` with the specified starting points and (optionally) barriers.
10. Group the `AGSUtilityElementTraceResult.elements` by their `networkSource.name`.
11. For every `AGSFeatureLayer` in this map with trace result elements, select features by converting `AGSUtilityElement`(s) to `AGSArcGISFeature`(s) using `AGSUtilityNetwork.featuresForElements()`

## Relevant API

* AGSUtilityNetwork
* AGSUtilityTraceParameters
* AGSUtilityTraceResult
* AGSUtilityElementTraceResult
* AGSUtilityNetworkDefinition
* AGSUtilityNetworkSource
* AGSUtilityAssetType
* AGSUtilityTerminal
* AGSUtilityElement
* AGSGeometryEngine.fractionAlongLine()

## About the data

The sample uses a dark vector basemap. It includes a subset of feature layers from a feature service that contains the same utility network used to run the connected trace.

## Tags

connected trace, utility network, network analysis