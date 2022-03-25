# Add features (feature service)

Add features to a feature layer.

![Add features (feature service) sample](add-features-feature-service.png)

## Use case

An end-user performing a survey may want to add features to the map during the course of their work.

## How to use the sample

Tap on a location on the map to add a feature at that location.

## How it works

An `AGSFeature` instance is added to an `AGSServiceFeatureTable`. Apply edits on the `ServiceGeodatabase` which contains the feature table to push the edits to the server.

1. Create and load an `AGSServiceFeatureTable`  with a feature service URL.
2. Get the `AGSServiceFeatureTable` from the service geodatabase.
3. Create an `AGSFeatureLayer` from the service feature table.
4. Create an `AGSFeature` with attributes and a location using the `AGSServiceFeatureTable`.
5. Add the `AGSFeature` to the `AGSServiceFeatureTable`.
6. Apply edits to the `AGSServiceGeodatabase` by calling `AGSServiceFeatureTable.applyEdits(completion:)`, which will upload the new feature to the online service.

## Relevant API

* AGSFeature
* AGSFeatureEditResult
* AGSFeatureLayer
* AGSServiceFeatureTable
* AGSServiceGeodatabase

## Tags

edit, feature, online service
