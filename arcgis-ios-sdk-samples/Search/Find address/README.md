# Find address

Find the location for an address.

![Find address sample](find-address.png)

## Use case

A user can input a raw address into your app's search bar and zoom to the address location.

## How to use the sample

For simplicity, the sample comes loaded with a set of suggested addresses. Choose an address from the suggestions or submit your own address to show its location on the map in a callout. Tap the pin to display the address on the map.

## How it works

1. Create an `AGSLocatorTask` using the URL to a locator service.
2. Create an instance of `AGSGeocodeParameters` and specify the `AGSGeocodeParameters.resultAttributeNames`.
3. Pass the `AGSGeocodeParameters` into `AGSLocatorTask.geocode(withSearchText:parameters:completion:)` and get the matching results from the `AGSGeocodeResult`.
4. Create an `AGSGraphic` with the geocode result's location and store the geocode result's attributes in the graphic's attributes.
5. Show the graphic in an `AGSGraphicsOverlay`.

## Relevant API

* AGSGeocodeParameters
* AGSGeocodeResult
* AGSLocatorTask

## About the data

This sample uses the [World Geocoding Service](https://www.arcgis.com/home/item.html?id=305f2e55e67f4389bef269669fc2e284).

## Tags

address, geocode, locator, search
