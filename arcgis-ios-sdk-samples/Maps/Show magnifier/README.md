#Show magnifier

This sample demonstrates how you can tap and hold on a map to get the magnifier. You can also pan while tapping and holding to move the magnifier across the map.

![](image1.png)

##How it works

`AGSMapView` has a property called `magnifierEnabled` that indicates whether a magnifier should be shown on the map when the user performs a tap and hold gesture. Its default value is `NO` or `false`. You can also use the `allowMagnifierToPanMap` property to indicate whether the map should be panned automatically when the magnifer gets near the edge of the map's bounds.





