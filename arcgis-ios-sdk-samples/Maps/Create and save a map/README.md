# Create and save map

Create and save a map as an portal item (i.e. web map).

![Image of create and save map 1](create-and-save-map-1.png)
![Image of create and save map 2](create-and-save-map-2.png)
![Image of create and save map 3](create-and-save-map-3.png)
![Image of create and save map 4](create-and-save-map-4.png)

## Use case

Maps can be created programmatically in code and then serialized and saved as an ArcGIS web map. A web map can be shared with others and opened in various applications and APIs throughout the platform, such as ArcGIS Pro, ArcGIS Online, the JavaScript API, Collector, and Explorer.

## How to use the sample

1. Select the basemap and layers you'd like to add to your map.
2. Tap the "Save" button.
3. Sign into an ArcGIS Online account.
4. Provide a title, tags, and description.
5. Save the map.

## How it works

1. An `AGSMap` is created with an `AGSBasemap` and a few operational layers.
2. An `AGSPortal` object is created and loaded. This will issue an authentication challenge, prompting the user to provide credentials.
3. Once the user is authenticated, call `AGSMap.save(as:portal:tags:folder:itemDescription:thumbnail:forceSaveToSupportedVersion:completion:)` and a new map is saved with the specified title, tags, and folder.

## Relevant API

* AGSMap
* AGSMap.save
* AGSPortal

## Tags

ArcGIS Online, ArcGIS Pro, portal, publish, share, web map
