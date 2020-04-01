# Reverse geocode

Use an online service to find the address for a tapped point.

![Reverse geocode sample](reverse-geocode.png)

## Use case

You might use a geocoder to find a customer's delivery address based on the location returned by their device's GPS.

## How to use the sample

Tap the map to see the nearest address displayed in a callout.

## How it works

1. Create an `AGSLocatorTask` object using a URL to a geocoder service.
2. Create an instance of `AGSReverseGeocodeParameters` and set `AGSReverseGeocodeParameters.maxResults` to 1.
3. Pass `AGSReverseGeocodeParameters` into `AGSLocatorTask.reverseGeocode(withLocation:parameters:completion:)` and get the matching results from the `AGSGeocodeResult`.
4. Show the results using an `AGSPictureMarkerSymbol` and add the symbol to an `AGSGraphic` in the `AGSGraphicsOverlay`.

## Relevant API

* AGSGeocodeParameters
* AGSLocatorTask
* AGSReverseGeocodeParameters

## Tags

address, geocode, locate, reverse geocode, search
