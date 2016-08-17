#Sketch on the map

This sample demonstrates how you can use the sketch editor to draw point or line or polygon geometry and do freehand sketch

##How to use the sample

The sample has a toolbar where you can choose between the sketching style. You can choose the type of geometry using the second switch. Sketch by tapping on the map or freehand drawing. There are tools to undo or redo an action or clear everything.

![](image1.png)
![](image2.png)
![](image3.png)

##How it works

The sample uses `AGSGeometrySketchEditor` class for the vertex based sketching and `AGSFreehandSketchEditor` class for freehand sketching. To set the type of geometry when using `AGSGeometrySketchEditor`, you need to assign the `geometryBuilder` property on `AGSSketchGraphicsOverlay`. It could be a `AGSPointBuilder` or `AGSPolylineBuilder` or `AGSPolygonBuilder`. While the `AGSFreehandSketchEditor` has a `currentGeometryType` enum to select the geometry type (only polyline and polygon are supported for freehand sketching). The sketch editor has a undo manager of type `NSUndoManager` that provides the undo and redo methods. To clear everything there is a `clear` method on the sketch editor.




