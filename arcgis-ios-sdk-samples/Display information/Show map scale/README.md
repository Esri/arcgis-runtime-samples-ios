# Show map scale

This sample demonstrates how to show a map scale in the basemap

## How to use the sample

The sample provides a map scale in the bottom screen, you can see the map scale using the map pinch gesture feature.

![](image1.png)

## How it works

A `UIView` and `UILabel` is added to the `UIViewController` in the `UIStoryboard` to show the map scale. After the pinch gesture is added to the `ViewDidLoad`. When called from the pinch gesture `mapPinchedByTouch` metod, the scale value of the base map is set on the scale label. 

