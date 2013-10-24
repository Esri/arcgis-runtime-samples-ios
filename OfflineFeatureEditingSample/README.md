##Offline Feature Editing Sample (Beta)

This sample demonstrates how you can download features from a sync-enabled ArcGIS Feature Serivce, display and edit
the features even when the devices does not have any network connectivity, synchronize changes with the service
to push your edits up and pull down any changes from the service. The sample displays basemap tiles for downtown 
San Francisco using a tile package (.tpk file) so that the basemap is visible even when the device is offline.


###Using the sample
1. Upon startup, the sample is in "Live" mode. The map displays features from an ArcGIS Feature service.
These features are refreshed every minute to ensure you can see any changes made on the service. The device needs a network connection
to ensure these features are displayed properly.
2. You can tap on any feature to view information about it in a popup. 
3. You can edit attributes, geometry, or attachments of the feature.
4. You can add new feature using the **+** button on the bottom toolbar.
5. Any edits you make while in "Live" mode are pushed immediately to the service.
6. You can tap the **download** button on the toolbar to download the features. The app now is in "Local" mode viewing
a local copy of the features in a replica geodatabase. You don't need any network connectivity once the features are downloaded.
7. You can tap on any feature to display information about it in a popup. 
8. You can edit attributes, geometry, or attachments of the feature.
9. Or you can add new feature using the **+** button on the bottom toolbar.
10. Any edits you make are held in the local geodatabase. These edits are displayed as a badge over the **Sync** button in the toolbar.
11. Assuming the device regains network connectivity, you can tap the **Sync** button to synchronize changes with the service. This will push your local edits up to the service
and bring down any changes from the service into your local geodatabase. 
12. After the sync completes, you can continue making edits in "Local" mode and synchronize as often as you like.
13. Tap the **switch to live** button when you're ready to start viewing live feature data from the service again. Your
local geodatabase is left intact in case you want to download features again.
14. Tap the **Delete** button to delete any local geodatabases that have been created.

![](/image.png)
![](/image2.png)
![](/image3.png)

###Key concepts
- 
-
