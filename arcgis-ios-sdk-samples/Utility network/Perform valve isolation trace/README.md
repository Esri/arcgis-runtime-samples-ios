# Perform valve isolation trace

Run a filtered trace to locate operable features that will isolate an area from the flow of network resources.

![Image of perform valve isolation trace with category comparison](perform-valve-isolation-trace-1.png)
![Image of perform valve isolation trace with filter barriers](perform-valve-isolation-trace-2.png)

## Use case

Determine the set of operable features required to stop a network's resource, effectively isolating an area of the network. For example, you can choose to return only accessible and operable valves: ones that are not paved over or rusted shut.

## How to use the sample

Tap on one or more features to use as filter barriers or create and set the configuration's filter barriers by selecting a utility category. Toggle "Isolated Features" to update trace configuration. Tap "Trace" to run a subnetwork-based isolation trace. Tap "Reset" to clear filter barriers and trace results.

## How it works

1. Create an `AGSMapView` object.
2. Create and load an `AGSServiceGeodatabase` with a feature service URL and get tables with their layer IDs.
3. Create an `AGSMap` object that contains `AGSFeatureLayer`(s) created from the service geodatabase's tables.
4. Create and load an `AGSUtilityNetwork` with the same feature service URL and map. Use `AGSGeoViewTouchDelegate.geoView(_:didTapAtScreenPoint:mapPoint:)` to get the `mapPoint` where a user tapped on the map.
5. Create `AGSUtilityTraceParameters` with `isolation` trace type and aa default starting location from a given asset type and global ID.
6. Get a default `AGSUtilityTraceConfiguration` from a given tier in a domain network. Set its `filter` property with an `AGSUtilityTraceFilter` object.
7. Add an `AGSGraphicsOverlay` for showing starting location and filter barriers.
8. Populate the choice list for the filter barriers from the `categories` property of `AGSUtilityNetworkDefinition`.
9. When the map view is tapped, identify which feature is at the tap location, and add an `AGSGraphic` to represent a filter barrier.
10. Create an `AGSUtilityElement` for the identified feature and add this element to the trace parameters' `filterBarriers` property.
    * If the element is a junction with more than one terminal, display a terminal picker. Then set the junction's `terminal` property with the selected terminal.
    * If it is an edge, set its `fractionAlongEdge` property using `AGSGeometryEngine.fraction(alongLine:to:tolerance:)` method.  
11. If "Trace" is tapped without filter barriers:
    * Create a new `AGSUtilityCategoryComparison` with the selected category and `AGSUtilityCategoryComparisonOperator.exists`.
    * Assign this condition to `AGSUtilityTraceFilter.barriers` from the default configuration from step 6.
    * Update the configuration's `includeIsolatedFeatures` property.
    * Set this configuration to the parameters' `traceConfiguration` property.
    * Run `AGSUtilityNetwork.trace(with:completion:)` with the specified parameters.

    If "Trace" is tapped with filter barriers:
    * Update `includeIsolatedFeatures` property of the default configuration from step 6.
    * Run `AGSUtilityNetwork.trace(with:completion:)` with the specified parameters.
12. For every `AGSFeatureLayer` in this map with trace result elements, select features by converting `AGSUtilityElement`(s) to `AGSArcGISFeature`(s) using `AGSUtilityNetwork.features(for:completion:)`.

## Relevant API

* AGSGeometryEngine.fraction(alongLine:to:tolerance:)
* AGSServiceGeodatabase
* AGSUtilityCategory
* AGSUtilityCategoryComparison
* AGSUtilityCategoryComparisonOperator
* AGSUtilityDomainNetwork
* AGSUtilityElement
* AGSUtilityElementTraceResult
* AGSUtilityNetwork
* AGSUtilityNetworkDefinition
* AGSUtilityTerminal
* AGSUtilityTier
* AGSUtilityTraceFilter
* AGSUtilityTraceParameters
* AGSUtilityTraceResult
* AGSUtilityTraceType

## About the data

The [Naperville gas network feature service](https://sampleserver7.arcgisonline.com/server/rest/services/UtilityNetwork/NapervilleGas/FeatureServer), hosted on ArcGIS Online, contains a utility network used to run the isolation trace shown in this sample.

## Additional information

Using utility network on ArcGIS Enterprise 10.8 requires an ArcGIS Enterprise member account licensed with the [Utility Network user type extension](https://enterprise.arcgis.com/en/portal/latest/administer/windows/license-user-type-extensions.htm#ESRI_SECTION1_41D78AD9691B42E0A8C227C113C0C0BF). Please refer to the [utility network services documentation](https://enterprise.arcgis.com/en/server/latest/publish-services/windows/utility-network-services.htm).

## Tags

category comparison, condition barriers, filter barriers, isolated features, network analysis, subnetwork trace, trace configuration, trace filter, utility network
