# Display grid

This sample demonstrates how to display and work with coordinate system grids such as LatitudeLongitude, MGRS, UTM and USNG on a map view. This includes toggling visibility, configuring layout and appearance preferences.

## How to use the sample

Tap on the `Change Grid` button in the toolbar to open the settings view. You can select type of grid from `Grid Type` (LatLong, MGRS, UTM and USNG) and modify it's properties like grid visibility, grid color, label visibility, label color, label position, label format and label unit.

![](image1.png)

## How it works

`AGSMapView` has a property called `grid` of type `AGSGrid` and is initially set to use the LatitudeLongitude grid. The controls allow to toggle visibility, configure layout and appearance of a grid with the following properties/methods:
- `isVisible` : Specifies whether the grid is visible or not
- `setLineSymbol:forLevel` : Set the grid line symbol with selected color
- `labelVisibility` : Specifies whether the grid's text labels are visible or not
- `setTextSymbol:forLevel` : Set the label text symbol with selected color
- `labelPosition` : Specifies the positioning of the grid's text labels.
- `labelFormat` : Specifies the format to use for the grid's text labels. Available only for LatitudeLongitude grid
- `labelUnit` : Specifies the units used in grid labels. Available only for MGRS and USNG grids


