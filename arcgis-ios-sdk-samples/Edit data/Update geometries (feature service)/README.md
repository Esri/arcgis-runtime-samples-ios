# Update geometries (feature service)

Update a feature's location in an online feature service.

![Map with features](update-geometries-1.png)
![Selected feature ](update-geometries-2.png)
![Feature in edit mode](update-geometries-3.png)
![Updated map](update-geometries-4.png)

## Use case

Sometimes users may want to edit features in an online feature service by moving them.

## How to use the sample

Tap a feature to select it. Tap the icon in the callout to begin updating the geometry. Tap the feature to select it, then tap on the map to update the geometry. Tap the "Done" button to complete the changes. An alert will be shown confirming success or failure.

## How it works

1. Create an `AGSServiceFeatureTable` object from a URL.
2. Create an `AGSFeatureLayer` object from the `AGSServiceFeatureTable`.
3. Find the layer of the selected feature using  `AGSGeoView.identifyLayer(_:screenPoint:tolerance:returnPopupsOnly:maximumResults:completion:)`. Which returns an `AGSIdentifyLayerResult` used to get the selected feature. 
4. Load the selected feature.
5. Change the selected feature's `AGSFeature.geometry` to change its location.
6. After the change, update the table on the server using `AGSServiceFeatureTable.applyEdits(completion:)`.

## Relevant API

* AGSFeature
* AGSFeatureLayer
* AGSServiceFeatureTable

## Tags

editing, feature layer, feature table, moving, service, updating
