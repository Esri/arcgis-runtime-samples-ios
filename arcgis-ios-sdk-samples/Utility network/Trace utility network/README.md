# Trace utility network

Discover connected features in a utility network using connected, subnetwork, upstream, and downstream traces.

![Image of trace utility network](trace-utility-network.png)

## Use case

You can use a trace to visualize and validate the network topology of a utility network for quality assurance. Subnetwork traces are used for validating whether subnetworks, such as circuits or zones, are defined or edited appropriately.

## How to use the sample

Tap on one or more features while "Start" or "Barrier" is selected. When a junction feature is identified, you may be prompted to select a terminal. When an edge feature is identified, the distance from the tapped location to the beginning of the edge feature will be computed. Tap "Type" to select the type of trace using the action sheet. Tap "Trace" to initiate a trace on the network. Tap "Reset" to clear the trace parameters and start over.

## How it works

1. Create an `AGSMapView` and listen for `didTap` events on the `AGSGeoViewTouchDelegate`.
2. Create and load an `AGSServiceGeodatabase` with a feature service URL and get tables with their layer IDs.
3. Create an `AGSMap` object that contains `AGSFeatureLayer`(s) created from the service geodatabase's tables.
4. Create and load an `AGSUtilityNetwork` with the same feature service URL and map.
5. Add an `AGSGraphicsOverlay` with symbology that distinguishes starting locations from barriers.
6. Identify tapped features on the map and add an `AGSGraphic` that represents its purpose (starting point or barrier) at the tapped location.
7. Create an `AGSUtilityElement` for the identified feature.
8. Determine the type of the identified feature using `AGSUtilityNetworkSource.sourceType`.
9. If the type is `junction`, display a terminal picker when more than one terminal is found and create an `AGSUtilityElement` using the selected terminal, or the single terminal if there is only one.
10. If the type is `edge`, create an `AGSUtilityElement` from the identified feature and compute how far along the edge the user tapped using `class AGSGeometryEngine.fraction(alongLine:to:tolerance:)`.
11. Add this `AGSUtilityElement` to a collection of starting locations or barriers.
12. Create `AGSUtilityTraceParameters` with the selected trace type along with the collected starting locations and barriers (if applicable).
13. Set the `AGSUtilityTraceConfiguration` with the utility tier's `traceConfiguration` property.
14. Run `AGSUtilityNetwork.trace(with:completion:)` with the specified starting points and (optionally) barriers.
15. Group the `AGSUtilityElementTraceResult.elements` by their `networkSource.name`.
16. For every `AGSFeatureLayer` in this map with trace result elements, select features by converting `AGSUtilityElement`(s) to `AGSArcGISFeature`(s) using `AGSUtilityNetwork.features(for:completion:)`.

## Relevant API

* AGSServiceGeodatabase
* AGSUtilityAssetType
* AGSUtilityDomainNetwork
* AGSUtilityElement
* AGSUtilityElementTraceResult
* AGSUtilityNetwork
* AGSUtilityNetworkDefinition
* AGSUtilityNetworkSource
* AGSUtilityTerminal
* AGSUtilityTier
* AGSUtilityTraceConfiguration
* AGSUtilityTraceParameters
* AGSUtilityTraceResult
* AGSUtilityTraceType
* AGSUtilityTraversability
* class AGSGeometryEngine.fraction(alongLine:to:tolerance:)

## About the data

The [Naperville electrical](https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer) network feature service, hosted on ArcGIS Online, contains a utility network used to run the subnetwork-based trace shown in this sample.

## Tags

condition barriers, downstream trace, network analysis, subnetwork trace, trace configuration, traversability, upstream trace, utility network, validate consistency
