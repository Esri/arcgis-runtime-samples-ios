# Create and save KML file

Construct a KML document and save it as a KMZ file.

![KML style settings](create-save-kml-1.png)
![Sketching a KML](create-save-kml-2.png)

## Use case

If you need to create and save data on the fly, you can use KML to create points, lines, and polygons by sketching on the map, customizing the style, and serializing them as KML nodes in a KML Document. Once complete, you can share the KML data with others that are using a KML reading application, such as ArcGIS Earth.

## How to use the sample

Tap on the middle button in the bottom toolbar to add a new KML. Select a type of feature and choose its color or icon. Tap on the map to sketch the KML. Tap the bottom middle button to complete the sketch. Tap the button on the right to save the KMZ file. Tap the left button to clear the current KML document.

## How it works

1. Create an `AGSKmlDocument`
2. Create an `AGSKmlDataset` using the `AGSKmlDocument`.
3. Create an `AGSKmlLayer` using the `AGSKmlDataset` and add it to `AGSMap.operationalLayers`.
4. Create `AGSGeometry` using `AGSSketchEditor`.
5. Project that `AGSGeometry` to WGS84 using `AGSGeometryEngine.projectGeometry(_:to:)`.
6. Create an `AGSKmlGeometry` object using that projected `AGSGeometry`.
7. Create an `AGSKmlPlacemark` using the `AGSKmlGeometry`.
8. Add the `AGSKmlPlacemark` to the `AGSKmlDocument`.
9. Set the `AGSKmlStyle` for the `AGSKmlPlacemark`.
10. When finished with adding `AGSKmlPlacemark` nodes to the `AGSKmlDocument`, save the `AGSKmlDocument` to a file using the `AGSKMLNode.save(toFileURL:completion:)` method.

## Relevant API

* AGSGeometryEngine.projectGeometry
* AGSKmlDataset
* AGSKmlDocument
* AGSKmlGeometry
* AGSKmlLayer
* AGSKMLNode.save
* AGSKmlPlacemark
* AGSKmlStyle
* AGSSketchEditor

## Tags

Keyhole, KML, KMZ, OGC
