# Feature layer rendering mode (map)

This sample demonstrates how to set the rendering mode for feature layers. There are two rendering modes, static and dynamic.

## How to use the sample

The sample shows two `AGSMapView`s, each showing the same set of feature layers. The feature layers in the top view are in dynamic mode, and the layers in the bottom view are in static mode. Tap 'Animated Zoom' to see the two views zoom in and out. Observe the differences in how the layers are rendered in each view. 

![](image.png)

## How it works

You can set the `renderingMode` on an `AGSFeatureLayer` to one of two options:

* `AGSFeatureRenderingMode.static` - the content is re-rendered after the view stops animating
* `AGSFeatureRenderingMode.dynamic` - the content is re-rendered continuously as the view is animating
