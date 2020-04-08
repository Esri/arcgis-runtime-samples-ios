# Format coordinates

Format coordinates in a variety of common notations.

![Image of format coordinates](format-coordinates.png)

## Use case

The coordinate formatter can format a map location in WGS84 in a number of common coordinate notations. Parsing one of these formats to a location is also supported. Formats include decimal degrees; degrees, minutes, seconds; Universal Transverse Mercator (UTM), and United States National Grid (USNG).

## How to use the sample

Tap on the map to see a callout with the tapped location's coordinate formatted in 4 different ways. You can also put a coordinate string in any of these formats in the text field. Hit return and the coordinate string will be parsed to a map location which the callout will move to.

## How it works

1. Get or create a map point `AGSPoint` with a spatial reference.
2. To get the formatted string, use one of the static methods below.
    * `class AGSCoordinateFormatter.latitudeLongitudeString(from:format:decimalPlaces:)`
    * `class AGSCoordinateFormatter.utmString(from:conversionMode:addSpaces:)`
    * `class AGSCoordinateFormatter.usngString(from:precision:addSpaces:)`
3. To get an `AGSPoint` from a formatted string, use one of the static methods below.
    * `class AGSCoordinateFormatter.point(fromLatitudeLongitudeString:spatialReference:)`
    * `class AGSCoordinateFormatter.point(fromUTMString:spatialReference:conversionMode:)`
    * `class AGSCoordinateFormatter.point(fromUSNGString:spatialReference:)`

## Relevant API

* AGSCoordinateFormatter
* AGSLatitudeLongitudeFormat
* AGSUTMConversionMode

## Tags

convert, coordinate, decimal degrees, degree minutes seconds, format, latitude, longitude, USNG, UTM
