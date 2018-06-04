# Style WMS Layer

Shows how to change the style of a WMS layer.

![](image1.png)

## How to use the sample

Once the layer loads, the segmented control will be enabled. Tap it to switch between the first and second styles of the WMS layer.

## How it works

To style a WMS Layer:

1. Create a layer using `AGSWMSLayer.init(url:layerNames:)`, specifying the URL of the service and the layer names you want.
2. When the layer is done loading, get it's list of style strings using `(layer.sublayers.firstObject as? AGSWMSSublayer)?.sublayerInfo.styles`.
3. Set one of the styles using `(layer.sublayers.firstObject as? AGSWMSSublayer)?.currentStyle`.

## Relevant API

* `AGSWMSLayer.init(url:layerNames:)`
* `AGSWMSLayer.load(completion:)`
* `AGSWMSLayerInfo.styles`
* `AGSWMSSublayer.currentStyle`

## Tags

WMS, Layer, Style
