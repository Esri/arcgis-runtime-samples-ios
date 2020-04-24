# Feature layer rendering mode (map)

Render features statically or dynamically by setting the feature layer rendering mode.

![Feature layer rendering mode (map) sample](feature-layer-rendering-map.png)

## Use case

In dynamic rendering mode, features and graphics are stored on the GPU. As a result, dynamic rendering mode is good for moving objects and for maintaining graphical fidelity during extent changes, since individual graphic changes can be efficiently applied directly to the GPU state. This gives the map or scene a seamless look and feel when interacting with it. The number of features and graphics has a direct impact on GPU resources, so large numbers of features or graphics can affect the responsiveness of maps or scenes to user interaction. Ultimately, the number and complexity of features and graphics that can be rendered in dynamic rendering mode is dependent on the power and memory of the device's GPU.

In static rendering mode, features and graphics are rendered only when needed (for example, after an extent change) and offloads a significant portion of the graphical processing onto the CPU. As a result, less work is required by the GPU to draw the graphics, and the GPU can spend its resources on keeping the UI interactive. Use this mode for stationary graphics, complex geometries, and very large numbers of features or graphics. The number of features and graphics has little impact on frame render time, meaning it scales well, and pushes a constant GPU payload. However, rendering updates is CPU and system memory intensive, which can have an impact on device battery life.

## How to use the sample

Use the "Animated Zoom" button to trigger the same zoom animation on both static and dynamically maps.

## How it works

1. Create an `AGSMapView` for each `dynamicMapView` and `staticMapView`.
2. Create `AGSServiceFeatureTable`s for point, polygon, and polyline services.
3. Create `AGSFeatureLayer`s for each of the `AGSServiceFeatureTable`s.
4. Make both a `dynamic` and `static` `AGSFeatureRenderingMode` for each of the feature layers and add each to the corresponding map view's `operationalLayers`.
5. Set the dynamic and static `AGSViewpoint`s for zoomed in and zoomed out using `AGSGeoView.setViewpoint(_:duration:completion:)`.

## Relevant API

* AGSFeatureLayer
* AGSFeatureRenderingMode
* AGSMap
* AGSMapView

## Tags

dynamic, feature layer, features, rendering, static
