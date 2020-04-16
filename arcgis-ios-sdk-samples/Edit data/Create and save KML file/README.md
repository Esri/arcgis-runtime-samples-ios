# Create and save KML file

Construct a KML document and save it as a KMZ file.

![KML style settings](create-save-kml-1.png)
![Sketching a KML](create-save-kml-2.png)

## Use case

If you need to create and save data on the fly, you can use KML to create points, lines, and polygons by sketching on the map, customizing the style, and serializing them as KML nodes in a KML Document. Once complete, you can share the KML data with others that are using a KML reading application, such as ArcGIS Earth.

## How to use the sample

Tap on the middle button in the bottom toolbar to add a new KML. Select a type of feature and choose its color or icon. Tap on the map to sketch the KML. Tap the bottom middle button to complete the sketch. Tap the button on the right to save the KMZ file. Tap the left button to clear the current KML document.

## How it works

1. Create an `AGSKMLDocument`.
2. Create an `AGSKMLDataset` using the `AGSKMLDocument`.
3. Create an `AGSKMLLayer` using the `AGSKMLDataset` and add it to the map's `operationalLayers` array.
4. Create `AGSGeometry` using `AGSSketchEditor`.
5. Project that `AGSGeometry` to WGS84 using `class AGSGeometryEngine.projectGeometry(_:to:)`.
6. Create an `AGSKMLGeometry` object using that projected `AGSGeometry`.
7. Create an `AGSKMLPlacemark` using the `AGSKMLGeometry`.
8. Add the `AGSKMLPlacemark` to the `AGSKMLDocument`.
9. Set the `AGSKMLStyle` for the `AGSKMLPlacemark`.
10. When finished with adding `AGSKMLPlacemark` nodes to the `AGSKMLDocument`, save the `AGSKMLDocument` to a file using the `AGSKMLNode.save(toFileURL:completion:)` method.

## Relevant API

* AGSGeometryEngine
* AGSKMLDataset
* AGSKMLDocument
* AGSKMLGeometry
* AGSKMLLayer
* AGSKMLNode
* AGSKMLPlacemark
* AGSKMLStyle
* AGSSketchEditor

## Tags

Keyhole, KML, KMZ, OGC
