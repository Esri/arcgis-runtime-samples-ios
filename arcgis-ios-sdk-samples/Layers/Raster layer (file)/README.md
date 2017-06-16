# Raster layer (file)

This sample demonstrates how to create and use a raster layer made from a local raster file.

![](image1.png)

## How it works

Create a `AGSRaster` from a raster file using the initializer `init(name:extension:)`. Raster layer is then created with the initializer `init(raster:)` provided on `AGSRasterLayer` that takes a `AGSRaster`. This raster layer is then added to the operational layers of the map



