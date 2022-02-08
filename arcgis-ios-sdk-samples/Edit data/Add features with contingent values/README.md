# Add features with contingent values

Create and add features whose attribute values satisfy a predefined set of contingencies.

![Add features with contingent values](add-features-contingent-values.png)

## Use case

Contingent values, are a data design feature that allows you to make values in one field dependent on values in another field. Your choice for a value on one field further constrain the domain values that can be placed on another field. In this way, contingent values enforce data integrity by applying additional constraints to reduce the number of valid field inputs. 

A field crew working in a sensitive habitat area may be required to stay a certain distance away from occupied bird nests, but the size of that exclusion area differs depending on the bird's level of protection according to presiding laws. Surveyors can add points of bird nests in the work area and their selection of how large the exclusion area is, will be contingent on the values in other attribute fields.

## How to use the sample

Tap on the map to add a feature symbolizing a bird's nest. Then choose values describing the nest's status, protection, and buffer size. Notice how different values are available depending on the values of preceeding fields. Once the contingent values are validated, tap "Done" to add the feature to the map.

## How it works

1. Create and load the `AGSGeodatabase`.
2. Load the first `AGSGeodatabaseFeatureTable` as an `AGSArcGISFeatureTable`.
3. Load the `AGSContingentValuesDefinition` from the feature table.
4. Create a new `AGSFeatureLayer` from the feature table and add it to the map.
5. Create a new `AGSFeature` using `AGSFeatureTable.createFeature()`
6. Get the initial options by getting the first field object by name using `AGSFeatureTable.field(forName:)`.
7. Then get get the field's `domain` and cast it as an `AGSCodedValueDomain`.
8. Get the coded value domain's `codedValues` to get an array of `AGSCodedValue`s.
9. After making the initial selection, retrieve the valid contingent values for each field as you select the values for the attributes.
    i. Get the `AGSContingentValueResult`s by using `contingentValues(with:field:)` with the feature and the target field by name.  
    ii. Get an array of valid `AGSContingentValues` from `AGSContingentValuesResult.contingentValuesByFieldGroup` dictionary with the name of the relevant field group.  
    iii. Iterate through the array of valid contingent values to create an array of `AGSContingentCodedValue` names or the minimum and maximum values of a `AGSContingentRangeValue` depending on the type of `AGSContingentValue` returned.  
10. Validate the feature's contingent values by using `validateContingencyConstraints(with:)` with the current feature. If the resulting array is empty, the selected values are valid.

## Relevant API

* AGSContingencyConstraintViolation
* AGSContingentCodedValue
* AGSContingentRangeValue
* AGSContingentValuesDefinition
* AGSContingentValuesResult
* AGSGeodatabase
* AGSGeodatabaseFeatureTable

## Offline data

This sample uses the [Contingent values birds nests](https://arcgisruntime.maps.arcgis.com/home/item.html?id=e12b54ea799f4606a2712157cf9f6e41). It is downloaded automatically.

## About the data

The geodatabase contains birds nests in the Filmore area, defined with contingent values. Each feature contains information about its status, protection, and buffer size.

## Tags

contingent values, contingent coded values, feature table, geodatabase
