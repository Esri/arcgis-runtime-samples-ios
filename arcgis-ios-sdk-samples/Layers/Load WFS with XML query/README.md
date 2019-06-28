# Load WFS with XML query

Load a WFS feature table using an XML query.

![Screenshot](image1.png)

## Use case

Runtime `AGSQueryParameters` objects can't represent all possible queries that can be made against a WFS feature service. For example, Runtime query parameters don't support wildcard searches. You can provide queries as raw XML strings, allowing you to access query functionality not available with `AGSQueryParameters `.

## How it works

1. Create an instance of `AGSWFSFeatureTable` and of `AGSFeatureLayer` to visualize the table.
2. Set the feature request mode to `manualCache`. 
3. Call `populateFromService(withRequestXML:clearCache:completion:)` to populate the table with only those features returned by the XML query.

## Relevant API

- `AGSFeatureLayer`
- `AGSWFSFeatureTable`
- `AGSWFSFeatureTable.axisOrder`
- `AGSWFSFeatureTable.populateFromService(withRequestXML:clearCache:completion:)`

## About the data

This service shows trees in downtown Seattle and the surrounding area. An XML-encoded `GetFeature` request is used to limit results to only trees of the genus *Tilia*.

For additional information, see the underlying service on [ArcGIS Online](https://arcgisruntime.maps.arcgis.com/home/item.html?id=1b81d35c5b0942678140efc29bc25391).

## Tags

OGC, WFS, feature, web, service, XML, query