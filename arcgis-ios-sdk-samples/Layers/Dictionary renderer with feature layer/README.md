# Dictionary renderer with feature layer

Convert features into graphics to show them with mil2525d symbols.

![Dictionary renderer with feature layer](dictionary-renderer-with-feature-layer.png)

## Use case

A dictionary renderer uses a style file along with a rule engine to display advanced symbology. 
This is useful for displaying features using precise military symbology.

## How to use the sample

Pan and zoom around the map. Observe the displayed military symbology on the map.

## How it works

1. Create an `AGSGeodatabase`.
2. Create and load an `AGSDictionarySymbolStyle` using the `mil2525d.stylx` resource.
3. Load the geodatabase using `AGSGeodatabase.load(completion:)`.
4. Once the geodatabase is done loading, create an `AGSFeatureLayer` from each of the geodatabase's `AGSGeodatabaseFeatureTable`s.
5. After the last `AGSFeatureLayer` has loaded, set the `AGSMapView`'s viewpoint to the full extent of all the layers using the method `AGSMapViewCommon.setViewpointGeometry(_:completion:)`.
6. Add the feature layer to the map's `operationalLayers`.
7. Create an `AGSDictionaryRenderer` and attach it to the feature layer.

## Relevant API

* AGSDictionaryRenderer
* AGSDictionarySymbolStyle

## Offline data

This sample uses the [Mil2525d Stylx File](https://www.arcgis.com/home/item.html?id=e34835bf5ec5430da7cf16bb8c0b075c) and the [Military Overlay geodatabase](https://www.arcgis.com/home/item.html?id=e0d41b4b409a49a5a7ba11939d8535dc). Both are downloaded from ArcGIS Online automatically.

## Tags

DictionaryRenderer, DictionarySymbolStyle, military, symbol
