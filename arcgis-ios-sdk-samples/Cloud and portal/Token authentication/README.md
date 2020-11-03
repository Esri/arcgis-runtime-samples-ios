# Token authentication

Access a web map that is secured with ArcGIS token-based authentication.

![Token Authentication sample](token-authentication.png)

## Use case

Allows you to access a secure service with the convenience and security of ArcGIS token-based authentication. For example, rather than providing a user name and password every time you want to access a secure service, you only provide those credentials initially to obtain a token which then can be used to access secured resources.

## How to use the sample

Upon opening the sample, you will be challenged for an ArcGIS Online login to view the protected map service. Enter a user name and password for an ArcGIS Online named user account (such as your ArcGIS for Developers account). If you authenticate successfully, the protected map service will display in the map view.

## How it works

1. Create an `AGSPortal` object.
2. Create an `AGSPortalItem` object for the protected web map using the portal and Item ID of the protected map service.
3. Create a map to display in the map view using `AGSMap.init(item:)`.
4. Assign the map to the map view.

## Relevant API

* AGSMap
* AGSMapView
* AGSPortal
* AGSPortalItem

## About the data

The [Traffic web map](https://arcgisruntime.maps.arcgis.com/home/item.html?id=e5039444ef3c48b8a8fdc9227f9be7c1) uses public layers as well as the world traffic (premium content) layer. The world traffic service presents historical and near real-time traffic information for different regions in the world. The data is updated every 5 minutes. This map service requires an ArcGIS Online organizational subscription.

## Additional information

Please note: the username and password are case sensitive for token-based authentication. If the user doesn't have permission to access all the content within the portal item, partial or no content will be returned.

## Tags

authentication, cloud, portal, remember, security
