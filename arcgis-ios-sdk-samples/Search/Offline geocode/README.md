# Offline geocode

Geocode addresses to locations and reverse geocode locations to addresses offline.

![Offline geocode sample](offline-geocode.png)

## Use case

You can use an address locator file to geocode addresses and locations. For example, you could provide offline geocoding capabilities to field workers repairing critical infrastructure in a disaster when network availability is limited.

## How to use the sample

Type the address in the text field or tap the arrow on the right and select from the list to geocode the address and view the result on the map. Tap the location you want to reverse geocode. Tap and hold to create a pin on the map  and pan while holding to get real-time geocoding.

## How it works

1. Create an `AGSLocatorTask` object. 
2. Set up `AGSGeocodeParameters` and call `AGSGeocode(withSearchText:parameters:completion:)` to get geocode results.

## Relevant API

* AGSGeocodeParameters
* AGSGeocodeResult
* AGSLocatorTask
* AGSReverseGeocodeParameters

## Offline data

The sample viewer will download offline data automatically before loading the sample.

* [San Diego Streets Tile Package](http://www.arcgis.com/home/item.html?id=1330ab96ac9c40a49e59650557f2cd63)
* [San Diego Offline Locator](http://www.arcgis.com/home/item.html?id=344e3b12368543ef84045ef9aa3c32ba)

## Tags

geocode, geocoder, locator, offline, package, query, search
