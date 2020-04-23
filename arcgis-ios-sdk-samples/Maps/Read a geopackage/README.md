# Read geopackage

Add rasters and feature tables from a geopackage to a map.

![Image of read geopackage 1](read-geopackage-1.png)
![Image of read geopackage 2](read-geopackage-2.png)

## Use case

The OGC GeoPackage specification defines an open standard for sharing raster and vector data. You may want to use GeoPackage files to support file-based sharing of geographic data.

## How to use the sample

When the sample loads, the feature tables and rasters from the GeoPackage will be shown on the map.

## How it works

1. Create a GeoPackage from a named bundle resource using `AGSGeoPackage.init(name:)`.
2. Load the GeoPackage using `AGSGeoPackage.load(completion:)` method.
3. Iterate through available rasters, exposed by `AGSGeoPackage.geoPackageRasters`.
    * For each raster, create an `AGSRasterLayer` object and add it to the map.
4. Iterate through available feature tables, exposed by `AGSGeoPackage.geoPackageFeatureTables`.
    * For each feature table, create an `AGSFeatureLayer` object and add it to the map.

## Relevant API

* AGSGeoPackage
* AGSGeoPackage.geoPackageFeatureTables
* AGSGeoPackage.geoPackageRasters
* AGSGeoPackageFeatureTable
* AGSGeoPackageRaster

## Offline data

The [Aurora Colorado GeoPackage](https://www.arcgis.com/home/item.html?id=68ec42517cdd439e81b036210483e8e7) holds datasets that cover Aurora, Colorado.

## About the data

This sample features a GeoPackage with datasets that cover Aurora, Colorado: Public art (points), Bike trails (lines), Subdivisions (polygons), Airport noise (raster), and liquor license density (raster).

## Additional information

GeoPackage uses a single SQLite file (.gpkg) that conforms to the OGC GeoPackage Standard. You can create a GeoPackage file (.gpkg) from your own data using the create a SQLite Database tool in ArcGIS Pro.

## Tags

container, GeoPackage, layer, map, OGC, package, raster, table
