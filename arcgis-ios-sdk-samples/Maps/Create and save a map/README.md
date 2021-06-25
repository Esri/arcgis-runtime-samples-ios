# Create and save a map

Create and save a map as a portal item (i.e. web map).

![Image of create and save map 1](create-and-save-map-1.png)
![Image of create and save map 2](create-and-save-map-2.png)
![Image of create and save map 3](create-and-save-map-3.png)
![Image of create and save map 4](create-and-save-map-4.png)

## Use case

Maps can be created programmatically in code and then serialized and saved as an ArcGIS web map. A web map can be shared with others and opened in various applications and APIs throughout the platform, such as ArcGIS Pro, ArcGIS Online, the JavaScript API, Collector, and Explorer.

## How to use the sample

Enter a username and password for an ArcGIS Online named user account (such as your ArcGIS for Developers account). Select the basemap and layers to add to the map. Tap the "Save" button. Provide a title, tags, description, and folder. Save the map.

## How it works

1. Add an `AGSOAuthConfiguration` to the `AGSAuthenticationManager`'s  `oAuthConfigurations` array and remove all credentials from the `credentialCache`.
2. Create a new `AGSPortal` and load it to invoke the authentication challenge.
3. Access the user's portal content by using `AGSPortal.user.fetchContent(completion:)`. Then get the array of `AGSPortalFolder`s.
4. Create an `AGSMap` with an `AGSBasemapStyle` and a few operational layers.
5. Save the map by using `AGSMap.save(as:portal:tags:folder:itemDescription:thumbnail:forceSaveToSupportedVersion:completion:)` and a new map is saved with the specified title, tags, and folder.

## Relevant API

* AGSMap
* AGSMap.save
* AGSPortal

## Tags

ArcGIS Online, ArcGIS Pro, portal, publish, share, web map
