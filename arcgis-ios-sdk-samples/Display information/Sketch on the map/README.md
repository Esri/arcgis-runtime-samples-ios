# Sketch on the map

Use the Sketch Editor to edit or sketch a new point, line, or polygon geometry on a map.

![Image of sketch on map 1](sketch-on-map-1.png)
![Image of sketch on map 2](sketch-on-map-2.png)

## Use case

A field worker could annotate features of interest on a map (via the GUI) such as location of dwellings (marked as points), geological features (polylines), or areas of glaciation (polygons).

## How to use the sample

Tap the add button to choose a geometry for the Sketch Editor. Use the toolbar to undo or redo changes made to the sketch on the graphics overlay. The graphics overlay can be cleared using the clear all button.

## How it works

1. Create an `AGSSketchEditor` and set it to the map view's `sketchEditor` property.
2. Use `AGSSketchEditor.start(with:creationMode:)` to start sketching. If editing an existing graphic's geometry, use `AGSSketchEditor.start(with:)`.
3. Check to see if undo and redo are possible during a sketch session with `canUndo` and `canRedo` using `AGSSketchEditor.undoManager`. If it's possible, use `AGSSketchEditor.undoManager.undo()` and `AGSSketchEditor.undoManager.redo()`.
4. To exit the sketch editor, use `AGSSketchEditor.stop()`.

## Relevant API

* AGSGeometry
* AGSGraphic
* AGSGraphicsOverlay
* AGSMapView
* AGSSketchCreationMode
* AGSSketchEditor

## Tags

draw, edit
