#Mobile map (search and route)

This sample demonstrates how to search and route using data in a map package.

##How to use the sample

The sample looks for map packages in the app bundle as well as the documents directory. All the resulting packages are shown in a table. You can tap on a single map package cell to see the maps inside the package. Each mobile map cell also indicates if the map has transportation network datasets or the package supports geocoding. You can tap on a mobile map and it should open in a map view. If the mobile map supports geocoding and/or routing you can tap on the map for the results.

![](image1.png)
![](image2.png)

##How it works

The sample uses `init(name:)` initializer on `AGSMobileMapPackage` to instantiate a map package object using the name of the package that you select. It uses the `locatorTask` property on `AGSMobileMapPackage` to check if the package supports geocoding. It uses the `transportationNetworks` property on each mobile map to see if routing is supported. The logic for routing and geocoding is similar to the one used in the individual routing and geocoding samples.





