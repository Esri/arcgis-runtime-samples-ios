##Offline Feature Editing Sample

This sample demonstrates how you can download features from a sync-enabled ArcGIS Feature Serivce, display and edit
the features even when the devices does not have any network connectivity, synchronize changes with the service
to push your edits up and pull down any changes from the service. The sample displays basemap tiles for downtown 
San Francisco using a tile package (.tpk file) so that the basemap is visible even when the device is offline. 
If the app is background'ed while features are being downloaded or changes are being synced, the app can continue to monitor the progess of those operations and post a notification when they complete. This depends upon the OS giving the app some execution time while it is in the background. You can simulate this on the simulator by first tapping the home button while the app is running to move it to the background, and then using the <i>Debug</i> > <i>Simulate Background Fetch</i> option in XCode.


###Using the sample
1. Upon startup, the app is in "Live Data" mode where the map displays features from an ArcGIS Feature service.
The device needs a network connection
to ensure these features are displayed properly.
2. You can tap on any feature to view information about it in a popup. 
3. You can edit attributes, geometry, or attachments of the feature.
4. You can add new feature using the **+** button on the bottom toolbar.
5. Any edits you make while in "Live" mode are pushed immediately to the service.
6. You can tap the **download** button on the toolbar to download the features to the device.  The app moves into "Local Data" mode, the map displays features from the replica geodatabase on the deivce. You don't need any network connectivity to view or edit features in this mode.
7. You can tap on any feature to display information about it in a popup. 
8. You can edit attributes, geometry, or attachments of the feature.
9. Or you can add new feature using the **+** button on the bottom toolbar.
10. Any edits you make are held in the local geodatabase. These edits are displayed as a badge over the **Sync** button in the toolbar.
11. Assuming the device regains network connectivity, you can tap the **Sync** button to synchronize changes with the service. This will push your local edits up to the service
and bring down any changes from the service into your local geodatabase. 
12. After the sync completes, you can continue making edits in "Local" mode and synchronize as often as you like.
13. Tap the **switch to live** button when you're ready to start viewing live feature data from the service again. Your
local geodatabase is left intact in case you want to download features again.
14. Tap the **Delete** button to delete all local geodatabases that have been created.

![](image.png)
![](image2.png)
![](image3.png)

###Using the API
The ```MainViewController``` contains an ```AGSMapView``` to display a map. The map contains ```AGSLocalTiledLayer``` to display basemap tiles from SanFrancisco.tpk tile package. 

In the "Live Data" mode, the map also contains ```AGSFeatureTableLayer``` based on  ```AGSGDBFeatureServiceTable``` for each layer in the [wildfire feature service](http://services.arcgis.com/P3ePLMYs2RVChkJx/arcgis/rest/services/Wildfire/FeatureServer)   to display & edit features. 

In the "Local Data" mode, the features are downloded from the service as a geodatabase using ```AGSGDBTask```. When the download completes, each dataset in the geodatabase accessed via ```AGSGDBFeatureTable``` and added to the map as an ```AGSFeatureTableLayer```. Features are  added, updated, or deleted using methods on ```AGSGDBFeatureTable``` and then later synchronized with the service using ```AGSGDBTask```

The app delegate uses the ```Background Helper``` utility class to continue downloading features or synchronizing changes if the user backgrounds the app or switches to another app while the operation is in progress. When the operation completes, local notifications are posted using the ```Background Helper``` if the app is still in the background. 