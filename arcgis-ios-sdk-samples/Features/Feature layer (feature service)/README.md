# Feature layer (feature service)

Show features from an online feature service.

![Feature layer (feature service)](feature-layer-service.png)

## Use case

Feature services are useful for sharing vector GIS data with clients so that individual features can be queried, displayed, and edited.

## How to use the sample

Run the sample and view the feature service as an operational layer on top of the basemap. Zoom and pan around the map to see the features in greater detail.

## How it works

1. Create an `AGSServiceFeatureTable` from a URL.
2. Create an `AGSFeatureLayer` from the service feature table.
3. Add the feature layer to map's array of `operationalLayers`.

## Relevant API

* AGSBasemap
* AGSFeatureLayer
* AGSMap
* AGSMapView
* AGSServiceFeatureTable

## Tags

feature table, layer, layers, service
