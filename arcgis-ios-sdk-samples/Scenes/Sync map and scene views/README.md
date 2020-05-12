# Sync map and scene views

Keep the view points of two views (e.g. MapView and SceneView) synchronized with each other.

![Sync map and scene views sample](sync-map-scene.png)

## Use case

You might need to synchronize GeoView viewpoints if you had two map views in one application - a main map and an inset. An inset map view could display all the layers at their full extent and contain a hollow rectangular graphic that represents the visible extent of the main map view. As you zoom or pan in the main map view, the extent graphic in the inset map would adjust accordingly.

## How to use the sample

Interact with the map view or scene view by zooming or panning. The other map view or scene view will automatically focus on the same viewpoint.

## How it works

1. Add `viewpointChangedHandler`s to both an `AGSMapView` and an `AGSSceneView`.
2. Track the user's `AGSViewpoint` and set that to each of the `AGSGeoView`s' viewpoints using `AGSGeoView.setViewpoint(_:)`

## Relevant API

* AGSGeoView
* AGSMapView
* AGSSceneView

## About the data

This application provides two different perspectives of the Imagery basemap. A 2D MapView as well as a 3D SceneView, displayed side by side.

## Tags

3D, automatic refresh, event, event handler, events, extent, interaction, interactions, pan, sync, synchronize, zoom
