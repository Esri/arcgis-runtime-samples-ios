# Display utility associations

Create graphics for utility associations in a utility network.

![Display utility associations sample](display-utility-association.png)

## Use case

Visualizing utility associations can help you to better understand trace results and the topology of your utility network. For example, connectivity associations allow you to model connectivity between two junctions that don't have geometric coincidence (are not in the same location); structural attachment associations allow you to model equipment that may be attached to structures; and containment associations allow you to model features contained within other features.

## How to use the sample

Pan and zoom around the map. Observe graphics that show utility associations between junctions.

## How it works

1. Create and load an `AGSUtilityNetwork` with a feature service URL.
2. Add an `AGSFeatureLayer` to the map for every `AGSUtilityNetworkSource` of type `edge` or `junction`.
3. Create an `AGSGraphicsOverlay` for the utility associations.
4. When the sample starts and every time the viewpoint changes, do the following steps.
5. Get the geometry of the map view's extent using `AGSMapView.currentViewpoint(with:).targetGeometry.extent`.
6. Get the associations that are within the current extent using `associations(withExtent:completion:)`.
7. Get the `AGSUtilityAssociationType` for each association.
8. Create an `AGSGraphic` using the `AGSGeometry` property of the association and a preferred symbol.
9. Add the graphic to the graphics overlay.

## Relevant API

* AGSGraphicsOverlay
* AGSUtilityAssociation
* AGSUtilityAssociationType
* AGSUtilityNetwork

## About the data

The [feature service](https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer) in this sample represents an electric network in Naperville, Illinois, which contains a utility network used to run the subnetwork-based trace.

## Tags

associating, association, attachment, connectivity, containment, relationships
