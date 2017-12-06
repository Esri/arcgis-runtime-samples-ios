# Raster function (service)

Raster functions are operations performed on a raster to apply on-the-fly processing. This sample demonstrates how to create an image service raster and apply a Hillshade raster function to it.

![](image1.png)

## How it works

- Create `AGSImageServiceRaster` using a `URL` and load it.
- Create `AGSRasterFunction` using a `JSON` string.
- Get raster function's arguments with `rasterFunction.arguments`
- Set image service raster in the raster function arguments with name using  `setRaster(_ raster: AGSRaster, withName name: String)`.
- Create `AGSRaster` using `AGSRasterFunction`.
- Create `AGSRasterLayer` using `AGSRaster`.
- Add `AGSRasterLayer`  to  `AGSMap.operationalLayers` array.


