# Perform valve isolation trace

Run a filtered trace to locate operable features that will isolate an area from the flow of network resources.

![Image of perform valve isolation trace](perform-valve-isolation-trace.png)

## Use case

Determine the set of operable features required to stop a network's resource, effectively isolating an area of the network. For example, you can choose to return only accessible and operable valves: ones that are not paved over or rusted shut.

## How to use the sample

Tap "Category" to create and set the configuration's filter barriers with a utility category. Toggle "Isolated Features" to update trace configuration. Tap "Trace" to run a subnetwork-based isolation trace.

## How it works

1. Create an `AGSMapView` object.
2. Create and load a `AGSUtilityNetwork` with a feature service URL.
3. Create an `AGSMap` object that contains `AGSFeatureLayer`(s) that are part of this utility network.
4. Create a default starting location from a given asset type and global ID.
5. Add an `AGSGraphicsOverlay` with an `AGSGraphic` that represents this starting location.
6. Populate the choice list for the filter barriers from the `categories` property of `AGSUtilityNetworkDefinition`.
7. Get a default `AGSUtilityTraceConfiguration` from a given tier in a domain network. Set it's `filter` property with an `AGSUtilityTraceFilter` object.
8. When "Trace" is tapped,
    * Create a new `AGSUtilityCategoryComparison` with the selected category and `AGSUtilityCategoryComparisonOperator.exists`. 
    * Assign this condition to `AGSUtilityTraceFilter.barriers` from the default configuration from step 7.
    * Update the configuration's `includeIsolatedFeatures` property.
    * Create an `AGSUtilityTraceParameters` object with `AGSUtilityTraceType.isolation` and default starting location from step 4.
    * Set this configuration to the parameters' `traceConfiguration` property, and then run the `AGSUtilityNetwork.trace(with:completion:)` method.
    * Run `AGSUtilityNetwork.trace(with:completion:)` with the specified parameters.
9. Group the `AGSUtilityElementTraceResult.elements` by their `networkSource.name`.
10. For every `AGSFeatureLayer` in this map with trace result elements, select features by converting `AGSUtilityElement`(s) to `AGSArcGISFeature`(s) using `AGSUtilityNetwork.features(for:completion:)`.

## Relevant API

* AGSUtilityCategory
* AGSUtilityCategoryComparison
* AGSUtilityCategoryComparisonOperator
* AGSUtilityDomainNetwork
* AGSUtilityElement
* AGSUtilityElementTraceResult
* AGSUtilityNetwork
* AGSUtilityNetworkDefinition
* AGSUtilityTraceFilter
* AGSUtilityTier
* AGSUtilityTraceParameters
* AGSUtilityTraceResult
* AGSUtilityTraceType

## About the data

The [Naperville gas network feature service](https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleGas/FeatureServer), hosted on ArcGIS Online, contains a utility network used to run the isolation trace shown in this sample.

## Tags

category comparison, condition barriers, isolated features, network analysis, subnetwork trace, trace configuration, trace filter, utility network