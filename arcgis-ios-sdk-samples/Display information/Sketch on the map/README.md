#Sketch on the map

This sample demonstrates how you can use the sketch graphics overlay to draw point or line or polygon geometry

##How to use the sample

The sample has a toolbar of sketch tools at the bottom. You can choose the type of geometry using the switch. Sketch by tapping on the map. There are tools to undo or redo an action or clear everything.

![](image1.png)
![](image2.png)

##How it works

To set the type of geometry, you need to assign the `geometryBuilder` property on `AGSSketchGraphicsOverlay`. It could be a `AGSPointBuilder` or `AGSPolylineBuilder` or `AGSPolygonBuilder`. The sketch graphics overlay has a undo manager of type `NSUndoManager` that provides the undo and redo methods. To clear everything there is a `clear` method on the sketch graphics overlay.




