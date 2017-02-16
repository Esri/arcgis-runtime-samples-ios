#Change viewpoint

This sample demonstrates different ways in which you can change the viewpoint or visible area of a map.

![](image1.png)
![](image2.png)

##How it works

`AGSMapView` provides different methods you can use to set the viewpoint. The app uses the `setViewpointGeometry(_:padding:completion:)` method to zoom to the Griffith Park geometry, `setViewpointCenter(_:scale:completion:)` method to zoom to London and `setViewpoint(_:duration:curve:completion:)` method for animation. Apart from these, there are some other methods (mentioned below) you can use.

* setViewpointCenter(_:completion:)
* setViewpointGeometry(_:completion:)
* setViewpointRotation(_:completion:)
* setViewpointScale(_:completion:)



