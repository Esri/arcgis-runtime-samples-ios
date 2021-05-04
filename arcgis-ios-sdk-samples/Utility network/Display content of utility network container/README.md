# Display content of utility network container

A utility network container allows a dense collection of features to be represented by a single feature, which can be used to reduce map clutter.

![Image of display content of utility network container](display-content-utility-network.png)

## Use case

Offering a container view for features aids in the review for valid structural attachment and containment relationships and helps determine if a dataset has an association role set. Container views often model a cluster of electrical devices on a pole top or inside a cabinet or vault.

## How to use the sample

Tap on a container feature to show all features inside the container. The container is shown as a polygon graphic with the content features contained within. The viewpoint and scale of the map are also changed to the container's extent. Connectivity and attachment associations inside the container are shown as dotted lines.

## How it works

1. Load a web map that includes ArcGIS Pro [Subtype Group Layers](https://pro.arcgis.com/en/pro-app/help/mapping/layer-properties/subtype-layers.htm) with only container features visible (i.e. fuse bank, switch bank, transformer bank, hand hole and junction box).
2. Create an `AGSMapView` and listen for `didTap` events on the `AGSGeoViewTouchDelegate`.
3. Create and load an `AGSUtilityNetwork`.
4. Add an `AGSGraphicsOverlay` for displaying a container view.
5. Identify the tapped feature and create an `AGSUtilityElement` from it.
6. Get the associations for this element using `AGSUtilityNetwork.associations(with:completion:)`.
7. Turn-off the visibility of all of the map's `operationalLayers`.
8. Get the features for the `AGSUtilityElement`(s) from the associations using `AGSUtilityNetwork.features(for:completion:)`.
9. Add an `AGSGraphic` with the same geometry and symbol as these features.
10. Add another `AGSGraphic` that represents this extent and zoom to this extent with some buffer.
11. Get associations for this extent using `AGSUtilityNetwork.associations(withExtent:completion:)`.
12. Add an `AGSGraphic` to represent the association geometry between them using a symbol that distinguishes between `attachment` and `connectivity` association type.
13. Turn-on the visibility of all `operationalLayers`, clear the `AGSGraphic` objects, and zoom out to previous extent to exit container view.

## Relevant API

* AGSSubtypeFeatureLayer
* AGSUtilityAssociation
* AGSUtilityAssociationType
* AGSUtilityElement
* AGSUtilityNetwork
* AGSUtilityNetworkDefinition  

## About the data

The [Naperville electric network feature service](https://sampleserver7.arcgisonline.com/arcgis/rest/services/UtilityNetwork/NapervilleElectric/FeatureServer), hosted on ArcGIS Online, contains a utility network used to find associations shown in this sample and a web map portal item, [Naperville electric containers](https://ss7portal.arcgisonline.com/arcgis/home/item.html?id=5b64cf7a89ca4f98b5ed3da545d334ef), that uses the same feature service endpoint, but displays only container features.

## Tags

associations, connectivity association, containment association, structural attachment associations, utility network
