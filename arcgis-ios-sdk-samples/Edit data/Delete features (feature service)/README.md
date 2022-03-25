# Delete features (feature service)

Delete features from an online feature service.

![Choose a feature to delete](delete-features-1.png)
![Confirm deletion](delete-features-2.png)

## Use case

Sometimes users may want to delete features from an online feature service.

## How to use the sample

Tap on a feature to display a callout. Tap on the trash can icon in the callout to delete the feature.

## How it works

1. Create and load an `AGSServiceGeodatabase` with a feature service URL.
2. Get the `AGSServiceFeatureTable` from the service geodatabase.
3. Create an `AGSFeatureLayer` from the service feature table.
4. Identify the selected feature by using `AGSGeoView.identifyLayer(_:screenPoint:tolerance:returnPopupsOnly:maximumResults:completion:)`.
5. Remove the selected features from the `AGSServiceFeatureTable` using `AGSFeatureTable.delete(_:completion:)`.
6. Update the data on the server using `AGSServiceGeodatabase.applyEdits(completion:)` on the `AGSServiceGeodatabase`, which will remove the feature from the online service.

## Relevant API

* AGSFeature
* AGSFeatureLayer
* AGSServiceFeatureTable
* AGSServiceGeodatabase

## Tags

deletion, feature, online, Service, table
