# Control graphic draw order

Change the drawing order for a graphic.

![Purple atop](control-graphic-draw-order-1.png)
![Blue atop](control-graphic-draw-order-2.png)

## Use case

Allows you to change the order of overlapping graphics in the map. For example, you may wish to bring a certain graphic to front so that it is not obscured by the other graphics.

## How to use the sample

The sample has four overlapping graphics. Tap on the respective graphic button in the bottom toolbar to bring that graphic to the front on the map.

## How it works

1. Create an `AGSGraphicsOverlay` and add it to the `AGSMapView`.
2. Create and add multiple `AGSGraphic` to the `AGSGraphicsOverlay`.
3. When the graphic button is tapped, it is given an `AGSGraphic.zIndex` bigger than all the other graphics. Hence it is redrawn atop all other graphics.

## Relevant API

* AGSGraphic
* AGSGraphic.zIndex
* AGSGraphicsOverlay
* AGSSimpleMarkerSymbol

## Tags

display, graphics, overlap, overlay
