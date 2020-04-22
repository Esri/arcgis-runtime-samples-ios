# Mobile map (search and route)

Display maps and use locators to enable search and routing offline using a mobile map package.

![Image of mobile map search and route 1](mobile-map-search-and-route-1.png)
![Image of mobile map search and route 2](mobile-map-search-and-route-2.png)

## Use case

Mobile map packages make it easy to transmit and store the necessary components for an offline map experience including transportation networks (for routing/navigation), locators (address search, forward and reverse geocoding), and maps. 

A field worker might download a mobile map package to support their operations while working offline.

## How to use the sample

A list of maps from a mobile map package will be displayed. If the map contains transportation networks, the list item will have a navigation icon. Tap on a map in the list to open it. If a locator task is available, tap on the map to reverse geocode the location's address. If transportation networks are available, a route will be calculated between geocode locations.

## How it works

1. Create an `AGSMobileMapPackage` from its path.
2. Get a list of maps inside the package using the `maps` property.
3. If the package has a locator, access it using the `locatorTask` property.
4. To see if a map contains transportation networks, check each map's `transportationNetworks` property.

## Relevant API

* AGSGeocodeResult
* AGSMobileMapPackage
* AGSReverseGeocodeParameters
* AGSRoute
* AGSRouteParameters
* AGSRouteResult
* AGSRouteTask
* AGSTransportationNetworkDataset

## Tags

disconnected, field mobility, geocode, network, network analysis, offline, routing, search, transportation
