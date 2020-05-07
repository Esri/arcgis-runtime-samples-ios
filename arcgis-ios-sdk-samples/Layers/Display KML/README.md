# Display KML

Display KML from a URL, portal item, or local KML file.

![Display KML sample](display-kml.png)

## Use case

Keyhole Markup Language (KML) is a data format used by Google Earth. KML is popular as a transmission format for consumer use and for sharing geographic data between apps. You can use Runtime to display KML files, with full support for a variety of features, including network links, 3D models, screen overlays, and tours.

## How to use the sample

Tap the toolbar button to select a source. A KML file from that source will be loaded and displayed in the map.

## How it works

1. To create a KML layer from a URL, create an `AGSKMLDataset` using the URL to the KML file. Then create an `AGSKMLLayer` using the dataset.
2. To create a KML layer from a portal item, construct an `AGSPortalItem` with an `AGSPortal` and the KML portal item ID. Then create an `AGSKMLLayer` using the `AGSPortalItem`.
3. To create a KML layer from a local file, create an `AGSKMLDataset` using the absolute file path to the local KML file. Then create an `AGSKMLLayer` using the dataset.
4. Add the layer to the map's `operationalLayers` array.

## Relevant API

* AGSKMLDataset
* AGSKMLLayer

## Offline data

This sample uses the [US State Capitals](https://www.arcgis.com/home/item.html?id=324e4742820e46cfbe5029ff2c32cb1f) KML. It is downloaded from ArcGIS Online automatically.

## About the data

This sample displays three different KML files:

* From URL - this is a map of the significant weather outlook produced by NOAA/NWS. It uses KML network links to always show the latest data.
* From local file - this is a map of U.S. state capitals. It doesn't define an icon, so the default pushpin is used for the points.
* From portal item - this is a map of U.S. states.

## Tags

keyhole, KML, KMZ, OGC
