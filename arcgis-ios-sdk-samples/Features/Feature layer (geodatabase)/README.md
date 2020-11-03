# Feature layer (geodatabase)

Display features from a local geodatabase.

![Feature layer (geodatabase)](feature-layer-geodatabase.png)

## Use case

Accessing data from a local geodatabase is useful when working in an environment that has an inconsistent internet connection or that does not have an internet connection at all. For example, a department of transportation field worker might source map data from a local geodatabase when conducting signage inspections in rural areas with poor network coverage.

## How to use the sample

Pan and zoom around the map. View the data loaded from the geodatabase.

## How it works

1. Create an `AGSGeodatabase` using the provided local resource, `LA_Trails`.
2. Use `AGSGeodatabase.load(completion:)` to load the geodatabase.
3. Get the `AGSGeodatabaseFeatureTable` with the name `Trailheads` from the geodatabase, `AGSGeodatabase.geodatabaseFeatureTable(withName:)`.
4. Create an `AGSFeatureLayer` using the table from above.
5. Add the feature layer to the map's array of `operationalLayers`.

## Relevant API

* AGSFeatureLayer
* AGSGeodatabase
* AGSGeodatabaseFeatureTable

## Offline data

This sample uses the [Los Angeles Vector Tile Package](https://www.arcgis.com/home/item.html?id=d9f8ce6f6ac84b90a665a861d71a5d0a) and [Los Angeles Trailheads geodatabase](https://www.arcgis.com/home/item.html?id=2b0f9e17105847809dfeb04e3cad69e0). Both are downloaded from ArcGIS Online automatically.

## About the data

The sample shows trailheads in the greater Los Angeles area displayed on top of a vector tile basemap.

## Additional information

One of the ArcGIS Runtime data set types that can be accessed via the local storage of the device (i.e. hard drive, flash drive, micro SD card, USB stick, etc.) is a mobile geodatabase. A mobile geodatabase can be provisioned for use in an ArcGIS Runtime application by ArcMap. The following provide some helpful tips on how to create a mobile geodatabase file:

In ArcMap, choose File > Share As > ArcGIS Runtime Content from the menu items to create the .geodatabase file (see the [create content document](https://desktop.arcgis.com/en/arcmap/latest/map/working-with-arcmap/creating-arcgis-runtime-content.htm)).

Note: You could also use the 'Services Pattern' and access the `AGSGeodatabase` class via a Feature Service served up via ArcGIS Online or ArcGIS Enterprise. Instead of using `AGSGeodatabase` to access the .geodatabase file on disk, you would use `AGSGeodatabaseSyncTask` to load a geodatabase from a URL instead. For more information review the [take a layer offline document](https://developers.arcgis.com/ios/latest/swift/guide/take-a-layer-offline.htm).

## Tags

geodatabase, mobile, offline
