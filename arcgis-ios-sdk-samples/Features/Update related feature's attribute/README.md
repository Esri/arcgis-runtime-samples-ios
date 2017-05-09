# Update related feature’s attribute

This sample shows how to query for related features and update their attributes.

![](image1.png)
![](image2.png)

## How to use the sample

Tap on a park (in green) to see its related preserves. Information on annual visitors to that preserve will be shown in a callout. You can edit this information by tapping on the accessory button in the callout and choosing a new value from the list. The symbol should be updated based on the new value and the callout should reflect the changes as well.

## How it works

The sample is preloaded with layers from a feature service. The relationships among the layers are defined in the service. Both the layers are shown on the map as an operational layer. As you tap on the map, `geoView(_:didTapAtScreenPoint:mapPoint:)` touch delegate method is invoked. Inside this method, an identify operation is performed to get features at the tapped location using identifyLayer(_:screenPoint:tolerance:returnPopupsOnly:completion:) method on `AGSMapView`. If a feature is found, the related features for that feature are queried using `queryRelatedFeaturesForFeature(_:completion:)` method on its feature table. The resulting preserve from the query is highlighted on the map. A callout is shown using `show(for:tapLocation:animated:)` method on `mapView.callout`. The callout delegate notifies when the accessory button is tapped. For setting the new value for the attribute, the feature is first loaded. Then the attribute value is set on the feature. Afterwards, the featureTable for the related feature is updated using `update(_:)`. And finally the changes are applied to the service using `applyEdits(completion:)`.
