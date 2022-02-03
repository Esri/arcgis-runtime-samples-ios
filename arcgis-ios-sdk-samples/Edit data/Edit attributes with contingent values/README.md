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
4. Load the first field object by name, "Status".
5. Load the `AGSFeatureTable` and use `AGSFeatureTable.createFeature` to create a feature.
6. Set the feature's first field group value by accessing the feature's array of `attributes` by key.
7. Get the `AGSContingentValueResult`s by using `contingentValues(with:field:)` with the feature and the next field object, "Protection".
8. Get the array of `AGSContingentCodedValue`s by getting the  `AGSContingentValuesResult.contingentValuesByFieldGroup` using the key, "ProtectionFieldGroup".
9. Choose the next value from the array of contingent coded values and set it to the feature's "Protection" attribute.
10. Continue choosing and getting contingent values for the remaining fields.
11. Validate the selected values by using `validateContingencyConstraints(with:)` with the feature. If the resulting array is empty, the selected values are valid.

## Relevant API

* AGSArcGISFeatureTable
* AGSContingentValueResult
* AGSContingentCodedValue
* AGSContingentValuesResult
* AGSFeatureTable

## Offline data

This sample uses the [Contingent values birds nests](https://arcgisruntime.maps.arcgis.com/home/item.html?id=e12b54ea799f4606a2712157cf9f6e41).

## About the data

The geodatabase contains birds nests in the Filmore area, defined with contingent values. Each feature contains information about its status, protection, and buffer size.

## Tags

contingent values, contingent coded values, feature table, geodatabase
