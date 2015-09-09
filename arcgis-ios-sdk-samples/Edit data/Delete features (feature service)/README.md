#Delete features (feature service)

This sample demonstrates how to delete features from a feature layer that uses a feature service.

##How to use the sample

Tap on a feature on the map. The callout should show. Tap on the trash button in the callout to delete the feature. An alert should show asking for confirmation

![](image1.png)
![](image2.png)

##How it works

The sample uses the `mapView:didTapAtPoint:mapPoint:` method on `AGSMapViewTouchDelegate` to get the tapped point. Queries the feature around that point using `queryFeaturesWithParameters:completion:` method on `AGSServiceFeatureTable`. It then shows a callout for that feature using the `showCalloutForFeature:layer:tapLocation:animated:` method on `mapView.callout`. When tapped on the trash icon, it deletes feature using `deleteFeature:completion:` method and applies the edit to the service using the `applyEditsWithCompletion:` method.




