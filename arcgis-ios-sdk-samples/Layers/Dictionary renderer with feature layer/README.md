# Dictionary renderer with feature layer

Convert features into graphics to show them with mil2525d symbols.

![](screenshot.png)

## Use case

A dictionary renderer uses a style file along with a rule engine to display advanced symbology. 
This is useful for displaying features using precise military symbology.

## How to use the sample

Simply run the sample.

## How it works

1. Create a `Geodatabase` using `Geodatabase(geodatabasePath)`.
1. Load the geodatabase asynchronously using `Geodatabase.loadAsync()`.
1. Instantiate a `SymbolDicitonary`  using `SymbolDictionary(specificationType)`.
   * `specificationType` will be the mil2525d.stylx file.
1. Load the symbol dictionary asynchronously using `DictionarySymbol.loadAsync()`.
1. Wait for geodatabase to completely load by connecting to `Geodatabase.addDoneLoadingListener()`.
1. Cycle through each `GeodatabaseFeatureTable` from the geodatabase using `Geodatabase.getGeodatabaseFeatureTables()`.
1. Create a `FeatureLayer` from each table within the geodatabase using `FeatureLayer(GeodatabaseFeatureTable)`.
1. Load the feature layer asynchronously with `FeatureLayer.loadAsync()`.
1. Wait for each layer to load using `FeatureLayer.addDoneLoadingListener`.
1. After the last layer has loaded, then create a new `Envelope` from a union of the extents of all layers.
   * Set the envelope to be the `Viewpoint` of the map view using `MapView.setViewpoint(new Viewpoint(Envelope))`.
1. Add the feature layer to map using `Map.getOperationalLayers().add(FeatureLayer)`.
1. Create `DictionaryRenderer(SymbolDictionary)` and attach to the feature layer using `FeatureLayer.setRenderer(DictionaryRenderer)`.

## Relevant API

* DictionaryRenderer
* SymbolDictionary

## Offline data

Read more about how to set up the sample's offline data [here](https://github.com/Esri/arcgis-runtime-samples-qt#use-offline-data-in-the-samples).

Link | Local Location
---------|-------|
|[Mil2525d Stylx File](https://www.arcgis.com/home/item.html?id=e34835bf5ec5430da7cf16bb8c0b075c)| `<userhome>`/ArcGIS/Runtime/Data/styles/mil2525d.stylx |
|[Military Overlay geodatabase](https://www.arcgis.com/home/item.html?id=e0d41b4b409a49a5a7ba11939d8535dc)| `<userhome>`/ArcGIS/Runtime/Data/geodatabase/militaryoverlay.geodatabase |

## Tags

DictionaryRenderer, DictionarySymbolStyle, military, symbol
