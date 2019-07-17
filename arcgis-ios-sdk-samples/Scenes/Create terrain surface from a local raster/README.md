# Create terrain from a local raster

Set the terrain surface with elevation described by a raster file.

![Create terrain from a local raster](create-terrain-from-a-local-raster.png)

## Use case

The terrain surface is what the basemap, operational layers, and graphics are draped on. Supported raster formats include:

* ASRP/USRP
* CIB1, 5, 10
* DTED0, 1, 2
* GeoTIFF
* HFA
* HRE
* IMG
* JPEG
* JPEG 2000
* NITF
* PNG
* RPF
* SRTM1, 2

## How it works

1. Create an `AGSScene` and add it to a `AGSSceneView`.
2. Create a `AGSRasterElevationSource` with a list of raster file paths.
3. Add this source to the scene's base surface: `elevationSources.append(rasterElevationSource)`.

## Relevant API

* AGSRasterElevationSource
* AGSSurface

## About the data

This raster data comes from Monterey, California.

## Offline data

1. Form a URL with a `Portal` item pointing to the raster file.
2.  Pass the URL into `AGSRasterElevationSource` to create an elevation source.

<table>
<tr>
<th> Link </th>
<th>Local Location</th>
</tr>
<tr>
<td><a href="https://arcgisruntime.maps.arcgis.com/home/item.html?id=98092369c4ae4d549bbbd45dba993ebc">Monterey Elevation Raster</a></td>
<td><code><userhome>/ArcGIS/Raster/dt2/MontereyElevation.dt2</code></td>
</tr>
</table>

## Tags

3D, raster, elevation, surface
