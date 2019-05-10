# Authenticate with OAuth

This sample demonstrates how to authenticate with ArcGIS Online (or your own portal) using OAuth2 to access secured resources (such as private web maps or layers). Accessing secured items requires a login on the portal that hosts them (an ArcGIS Online account, for example).

Your app may need to access items that are only shared with authorized users. For example, your organization may host private data layers or feature services that are only accessible by verified users. You may also need to take advantage of premium ArcGIS Online services, such as geocoding or routing, that require a named user login.

![Screenshot 1](image1.png) ![Screenshot 2](image2.png)

## Instructions

1. When you run the sample, the app will load a web map that contains premium content.
2. You will be challenged for an ArcGIS Online login in order to view that layer (world traffic).
3. Enter a user name and password for an ArcGIS Online named user account (such as your ArcGIS for Developers account).
4. If you authenticate successfully, the traffic layer will display, otherwise the map will contain only the public basemap layer.
5. You can alter the code to supply OAuth configuration settings specific to your app.

## How it works

1. When the app loads, a web map containing premium content (world traffic service) is loaded in the map view.
2. In response to the attempt to access secured content, the `AGSAuthenticationManager` shows an OAuth authentication dialog from ArcGIS Online.
3. If the user authenticates successfully, the world traffic service appears in the map. Otherwise, only the basemap appears.

## Relevant API

- `AGSOAuthConfiguration`
- `AGSAuthenticationManager`
- `AGSPortal`
 
## Tags

Authentication, Security, OAuth