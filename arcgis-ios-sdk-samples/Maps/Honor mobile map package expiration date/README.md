# Honor mobile map package expiration date

Access the expiration information of an expired mobile map package.

![Screenshot of Honor Mobile Map Package Expiration Date Sample](image1.png)

## Use case

The data contained within a mobile map package (MMPK) may only be relevant for a fixed period of time. Using ArcGIS Pro, the author of an MMPK can set an expiration date to ensure the user is aware the data is out of date.

As long as the author of an MMPK has set an expiration date, the expiration date can be read even if the MMPK has not yet expired. For example, developers could also use this API to warn app users that an MMPK may be expiring soon.

## How to use the sample

Load the app. The author of the MMPK used in this sample chose to set the MMPK's map as still readable, even if it's expired. The app presents expiration information to the user.

## How it works

1. Create an `AGSMobileMapPackage` object, passing in the URL to the mobile map package's location.
2. Load the mobile map package.
3. Present the mobile map package's expiration information to the user:
  - Use `AGSExpiration.message` to get the expiration message set by the author of the MMPK.
  - Use `AGSExpiration.dateTime` to get the expiration date set by the author of the MMPK.

## Relevant API

- `AGSExpiration`
- `AGSMobileMapPackage`

## Offline Data

This sample uses the [LothianRiversAnno - Expired](https://arcgisruntime.maps.arcgis.com/home/item.html?id=174150279af74a2ba6f8b87a567f480b) Mobile Map Package. It is downloaded from ArcGIS Online automatically.

## Tags

expiration, mmpk
