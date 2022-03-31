# Update attributes (feature service)

Update feature attributes in an online feature service.

![Select a feature to update](update-attributes-1.png)
![Callout of selected feature is shown](update-attributes-2.png)
![List of damage types](update-attributes-3.png)
![Updated attribute](update-attributes-4.png)

## Use case

Online feature services can be updated with new data. This is useful for updating existing data in real time while working in the field.

## How to use the sample

To change the feature's damage property, tap the feature to select it, tap the icon in the callout, then choose a new damage type.

## How it works

1. Create and load an `AGSServiceGeodatabase` with a feature service URL.
2. Get the `AGSServiceFeatureTable` from the service geodatabase.
3. Create an `AGSFeatureLayer` from the service feature table.
4. Select features from the `AGSFeatureLayer`.
5. Change the selected feature's attributes.
6. Update the table with `AGSFeatureTable.update(_:completion:)`.
7. Apply edits to the `AGSServiceGeodatabase` by calling `AGSServiceGeodatabase.applyEdits(completion:)`, which will update the feature on the online service.

## Relevant API

* AGSArcGISFeature
* AGSFeatureLayer
* AGSServiceFeatureTable
* AGSServiceGeodatabase

## Tags

amend, attribute, details, edit, editing, information, value
