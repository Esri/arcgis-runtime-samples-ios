# Display device location with NMEA data sources

Parse NMEA sentences and use the results to show device location on the map.

![Image of Display device location with NMEA data sources](display-device-location-with-NMEA-data-sources.png)

## Use case

NMEA sentences can be retrieved from GPS receivers and parsed into a series of coordinates with additional information. Devices without a built-in GPS receiver can retrieve NMEA sentences by using a separate GPS dongle, commonly connected Bluetooth or through a serial port.

The NMEA location data source allows for detailed interrogation of the information coming from the GPS receiver. For example, allowing you to report the number of satellites in view.

## How to use the sample

Tap "Source" to choose between a simulated location data source and any data source created from a connected GNSS device, and initiate the location display. Tap "Recenter" to recenter the location display. Tap "Reset" to reset the location display and location data source.

## How it works

1. Load NMEA sentences.
    * If a supported GNSS surveyor is connected, the sample can get NMEA updates from it.
    * Otherwise, the sample will read mock data from a local file.
2. Create an `AGSNMEALocationDataSource`. There are 2 methods to provide updates to the data source.
    * When updates are received from a GNSS device or the mock data provider, push the data into `AGSNMEALocationDataSource`.
    * In the Runtime SDK 100.11.0 release, it is also supported to create an `AGSNMEALocationDataSource` with the GNSS device connected via `EAAccessory` and its protocol listed in `UISupportedExternalAccessoryProtocols`.
3. Set the `AGSNMEALocationDataSource` to the location display's data source.
4. Start the location display to begin receiving location and satellite updates.

## Relevant API

* AGSLocation
* AGSLocationDisplay
* AGSNMEALocationDataSource
* AGSNMEASatelliteInfo

## About the data

A list of NMEA sentences is used to initialize a `SimulatedNMEADataSource` object. This simulated data source provides NMEA data periodically, and allows the sample to be used on devices without a GPS dongle that produces NMEA data.

The route taken in this sample features a [2-minute driving trip around Redlands, CA](https://arcgis.com/home/item.html?id=d5bad9f4fee9483791e405880fb466da).

## Additional Information

To support GNSS device connection in an app, here are a few steps:

* Enable Bluetooth connection in the Settings, or connect via Lightning connector.
* Refer to the device manufacturer's documentation to get its protocol string, and add the protocol to the app’s `Info.plist` under the key `UISupportedExternalAccessoryProtocols`.
* When working with any MFi accessory, the end user must register their iOS app with the accessory manufacturer first to whitelist their app before submitting it to the AppStore for approval. This is a requirement by Apple and stated in the iOS Developer Program License Agreement.

Please read Apples documentation below for further details.

* [`EAAccessory`](https://developer.apple.com/documentation/externalaccessory)
* [`UISupportedExternalAccessoryProtocols`](https://developer.apple.com/documentation/bundleresources/information_property_list/uisupportedexternalaccessoryprotocols)

## Tags

Bluetooth, dongle, GNSS, GPS, history, navigation, NMEA, real-time, trace
