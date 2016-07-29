#Map loaded

This sample shows you the map's load status. The LoadStatus is considered loaded when any of the following are true:

- The map has a valid spatial reference
- The map has an initial viewpoint
- One of the map's predefined layers has been created.

![](image1.png)

##How it works

The sample uses Key-Value Observing on the `AGSMap`’s `loadStatus` property to determine when the status has changed.



