# Browse building floors

Display and browse through building floors from a floor-aware web map.

![Browse building floors](browse-building-floors.png)

## Use case

Having map data to aid indoor navigation in buildings with multiple floors such as airports, museums, or offices can be incredibly useful. For example, you may wish to browse through all available floor maps for an office in order to find the location of an upcoming meeting in advance.

## How to use the sample

Use the picker to browse different floor levels in the facility. Only the selected floor will be displayed.

## How it works

1. Create and load a floor-aware web map using the identifier of an `AGSPortalItem`.
2. Load the map and retrieve the map's `floorManager` property. Check that the map has a `floorManager` or `floorDefinition` property to ensure the map is floor-aware.
3. Load the floor manager and retrieve the floor-aware data.
4. Set the current visible floor to the first floor by finding the `AGSFloorLevel` whose `verticalOrder` property equals zero.
5. When an `AGSFloorLevel` is selected, set only the selected floor level to visible using the `isVisible` property.

## Relevant API

* AGSFloorLevel
* AGSFloorManager

## About the data

This sample uses a [floor-aware web map](https://arcgis.com/home/item.html?id=f133a698536f44c8884ad81f80b6cfc7) that displays the floors of Building L on the Esri Redlands campus.

## Additional information

The `AGSFloorManager` API also supports browsing different sites and facilities in addition to building floors.

Floor-awareness APIs support both maps and scenes. To learn more about floor-aware maps, read the [Configure floor-aware maps](https://pro.arcgis.com/en/pro-app/latest/help/data/indoors/configure-floor-aware-maps.htm) article.

## Tags

building, facility, floor, floor-aware, floors, ground floor, indoor, level, site, story
