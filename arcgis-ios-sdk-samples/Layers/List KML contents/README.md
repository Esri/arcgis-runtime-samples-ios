# List KML contents

List the contents of a KML file. KML files can contain a hierarchy of features, including network links to other KML content.

![](image1.png)

## How to use the sample

The root nodes of the KML file are shown in the table view. Tap a node to see its children and its extent, shown in a scene view. Not all nodes have an extent (e.g. screen overlays).

## How it works

1. A local KML file is loaded as an `AGSKMLDataset` to be used throughout the sample.
2. All KML nodes are recursively set to be visible since some nodes may not be visible by default.
3. The nodes of the `AGSKMLDataset` are explored recursively to populate the nested table views, starting with the `rootNodes` property.
4. In each table where the node has an extent, the dataset is shown as a `AGSKMLLayer` in a `AGSSceneView`. A viewpoint for the node is created, if possible, and set with the `setViewpoint` function of `AGSSceneView`.

## Relevant API

* `AGSKMLDataset`
* `AGSKMLNode`
* `AGSKMLLayer`

## About the data

This is an example KML file meant to demonstrate how Runtime supports several common features.

## Tags

KML, KMZ, OGC, Keyhole