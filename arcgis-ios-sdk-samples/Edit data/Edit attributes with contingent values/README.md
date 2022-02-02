# Add features with contingent values

Add features with multiple, dependent attributes.

![Edit and sync features](edit-and-sync-features.png)

## Use case

Contingent values, are a data design feature that allows you to make values in one field dependent on values in another field. Your choice for a value on one field further constrain the domain values that can be placed on another field. In this way, contingent values enforce data integrity by applying additional constraints to reduce the number of valid field inputs. 

A survey worker following endangered birds may use this workflow to keep track of the birds' nests. They can log important information such as nest status, protection level, and nest buffer distance. Each list of options is dependent on the previous selection. 

## How to use the sample

Tap on the map to add a feature symbolizing a bird's nest. Then choose values describing the nest's status, protection, and buffer size. Once the contingent values are validated, tap "Done" to add the feature to the map.

## How it works

1. Create and load the `AGSGeodatabase`.
2. Load the first `AGSFeatureTable` as an `AGSArcGISFeatureTable`.
3. Load and add the first `AGSFeatureLayer`.
4. Start the job and get a geodatabase as a result.
5. Set the sync direction to `.bidirectional`.
6. To enable editing, load the geodatabase and get its feature tables. Create feature layers from the feature tables and add them to the map's operational layers collection.
7. Create an `AGSSyncGeodatabaseJob` object using `AGSGeodatabaseSyncTask.syncJob(with:geodatabase:)`, passing in the parameters and geodatabase as arguments.
8. Start the sync job to synchronize the edits.

## Relevant API

* AGSFeatureLayer
* AGSFeatureTable
* AGSGenerateGeodatabaseJob
* AGSGenerateGeodatabaseParameters
* AGSGeodatabaseSyncTask
* AGSSyncGeodatabaseJob
* AGSSyncGeodatabaseParameters
* AGSSyncLayerOption

## Offline data

This sample uses the [Contingent values birds nests](https://arcgisruntime.maps.arcgis.com/home/item.html?id=e12b54ea799f4606a2712157cf9f6e41).

## About the data

The geodatabase contains birds nests in the Filmore area, defined with contingent values. Each feature contains information about its status, protection, and buffer size.

## Tags

feature service, geodatabase, offline, synchronize
