# Query a map image sublayer

Find features in a sublayer based on attributes and location.

![Query a map image sublayer sample](query-map-image.png)

## Use case

Sublayers of an `AGSArcGISMapImageLayer` may expose an `AGSFeatureTable`. This allows you to perform the same queries available when working with a table from an `AGSFeatureLayer` attribute query, spatial query, statistics query, query for related features, etc. An image layer with a sublayer of counties can be queried by population to only show those above a minimum population.

## How to use the sample

Specify a minimum population in the input field (values under 1810000 will produce a selection in all layers) and tap the "Query" button to query the sublayers in the current view extent. After a short time, the results for each sublayer will appear as graphics.

## How it works

1. Create an `AGSArcGISMapImageLayer` object using the URL of an image service.
2. After loading the layer, get the sublayer you want to query with from the map image layer's `mapImageSublayers` array.
3. Load the sublayer, and then get its `AGSFeatureTable`.
4. Create `AGSQueryParameters` and define its `whereClause` and `geometry`.
5. Use `AGSFeatureTable.queryFeatures(with:completion:)` to get an `AGSFeatureQueryResult` with features matching the query. The result is an iterable of features.

## About the data

The `AGSArcGISMapImageLayer` in the map uses the "USA" map service as its data source. This service is hosted by ArcGIS Online, and is composed of four sublayers: "states", "counties", "cities", and "highways".
Since the `cities`, `counties`, and `states` tables all have a `POP2000` field, they can all execute a query against that attribute and a map extent.

## Relevant API

* AGSArcGISMapImageLayer
* AGSArcGISMapImageSublayer
* AGSQueryParameters
* AGSFeatureTable

## Tags

search and query
