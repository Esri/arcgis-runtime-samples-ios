# Manage operational layers

Add, remove, and reorder operational layers in a map.

![Image of manage operational layers 1](manage-operational-layers-1.png)
![Image of manage operational layers 2](manage-operational-layers-2.png)

## Use case

Operational layers display the primary content of the map and usually provide dynamic content for the user to interact with (as opposed to basemap layers that provide context).

The order of operational layers in a map determines the visual hierarchy of layers in the view. You can bring attention to a specific layer by rendering above other layers.

## How to use the sample

Tap the toolbar button to display the operational layers that are currently displayed in the map. In the first section, tap "-" button to remove a layer, or tap and hold the reordering control and drag to reorder a layer. The map will be updated automatically.

The second section shows layers that have been removed from the map. Tap one to add it back to the map.

## How it works

1. Get the operational layers from the map's `operationalLayers` property.
2. Add or remove layers by modifying the `operationalLayers` array. The last layer in the array will be rendered on top.

## Relevant API

* AGSLayer
* AGSMap

## Additional information

You cannot add the same layer to the map multiple times or add the same layer to multiple maps. Instead, clone the layer using `AGSLayer.copy()` to create a new instance.

## Tags

add, delete, layer, map, remove
