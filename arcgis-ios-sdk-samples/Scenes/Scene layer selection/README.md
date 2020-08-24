# Scene layer selection

Identify features in a scene to select.

![Scene Layer Selection sample](scene-layer-selection.png)

## Use case

You can select features to visually distinguish them with a selection color or highlighting. This can be useful to demonstrate the physical extent or associated attributes of a feature, or to initiate another action such as centering that feature in the scene view.

## How to use the sample

Tap on a building in the scene layer to select it. Deselect buildings by tapping away from the buildings.

## How it works

1. Create an `AGSArcGISSceneLayer` passing in the URL to a scene layer service.
2. Use the `AGSGeoViewTouchDelegate` to get the screen tapped location.
3. Use `AGSGeoView.identifyLayer(_:screenPoint:tolerance:returnPopupsOnly:completion:)` to identify features in the scene.
4. From the resulting `AGSIdentifyLayerResult`, get the list of identified `AGSGeoElement`s.
5. Get the first `AGSFeature` in the list and use `AGSArcGISSceneLayer.select(_:)` to select it.

## Relevant API

* AGSArcGISSceneLayer
* AGSGeoViewTouchDelegate
* AGSScene
* AGSSceneView

## About the data

This sample shows a [Berlin, Germany Scene](https://www.arcgis.com/home/item.html?id=31874da8a16d45bfbc1273422f772270) hosted on ArcGIS Online.

## Tags

3D, Berlin, buildings, identify, model, query, search, select
