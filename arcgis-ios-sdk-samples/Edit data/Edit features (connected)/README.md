# Edit features (connected)

View, edit, or add features using a popup.

![Map with features](edit-features-connected-1.png)
![List of templates](edit-features-connected-2.png)
![Editable information list](edit-features-connected-3.png)

## Use case

An end-user performing a survey may want to view, edit, or add features on a map using a popup during the course of their work.

## How to use the sample

Pan and zoom to explore various features. Tap on an existing feature to view or edit its data. Tap the "Add new feature" button to add a new feature to the map.

## How it works

1. Create and load an `AGSServiceGeodatabase` with a feature service URL.
2. Get the `AGSServiceFeatureTable` from the service geodatabase.
3. Create an `AGSFeatureLayer` from the service feature table.
4. Select features using `AGSGeoView.identifyLayer(_:screenPoint:tolerance:returnPopupsOnly:maximumResults:completion:)` and `AGSIdentifyLayerResult`.
5. Create an `AGSPopup` to display data and allow editing.
6. Create a new feature with a specific template using `AGSArcGISFeatureTable.createFeature(with:)`.
6. Update the data on the server using `AGSServiceGeodatabase.applyEdits(completion:)` on the `AGSServiceGeodatabase`, which apply the changes on the online service.

## Relevant API

* AGSFeatureLayer
* AGSFeatureTemplate
* AGSPopup
* AGSServiceFeatureTable
* AGSServiceGeodatabase

## Tags

details, edit, editing, feature, information, popup, template, value
