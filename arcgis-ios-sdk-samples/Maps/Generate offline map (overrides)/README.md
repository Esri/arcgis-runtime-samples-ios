# Generate Offline Map (Overrides)

## Description
Use the `AGSOfflineMapTask`, with the overrides, to take a webmap offline. The overrides workflow allows you to adjust the settings used for taking each layer in the map offline. For a simple example of how you take a map offline, please consult the "Generate Offline Map" sample.

For applications where you just need to take all layers offline, use the standard workflow (using only `AGSGenerateOfflineMapParameters`). For more fine-grained control over the data you are taking offline, use overrides to adjust the settings for each layer (`AGSGenerateOfflineMapParameters` in conjunction with `AGSGenerateOfflineMapParameterOverrides`). Some example use cases for the overrides approach could be when you need to:

- adjust the extent for one or more layers to be different to the rest of the map.
- reduce the amount of data (for example tile data) downloaded for one or more layers in the map.
- filter features to be taken offline.
- take features with no geometry offline - for example, features whose attributes have been populated in the office, but which need a site survey for their geometry.


As the web map that is being taken offline contains an Esri basemap, this sample requires that you sign in with an ArcGIS Online organizational account.


![](image1.png)

## How to use the sample
1. Follow the prompts to sign into arcgis.com.
2. Tap the "Generate Offline Map (Overrides)" button.
3. Use the sliders to adjust the minimum and maximum scale levels of the Streets basemap to be taken offline.
4. Use the slider to set the buffer radius for the Streets basemap. 
5. Turn off the switches to skip the System Valves and Service Connections layers.
6. Use the slider to set the minimum flow rate for the features from the Hydrant layer.
7. Turn off the switch to skip the geometry filter for the water pipes features.
8. Click "Start Job"
9. Watch the progress bar as the task completes.
10. If you changed all the settings, notice the following in the generated map:
    - The basemap does not allow you to zoom past a certain range.
    - The basemap is padded around the original area of interest.
    - The pipe layers extends beyond the target area.
    - The System Valves and Service Connections are omitted.
    - The Hydrants layer contains a subset of the original features.

# How it works
The sample creates a `AGSPortalItem` object using a web map’s ID. This portal item is also used to initialize a map and an `AGSOfflineMapTask` object. When the button is clicked, the sample requests the default parameters for the task, with the selected extent, by calling `defaultGenerateOfflineMapParameters` on the `AGSOfflineMapTask`. Once the parameters are retrieved, they are used to create a set of `AGSGenerateOfflineMapParameterOverrides` by calling `generateOfflineMapParameterOverrides` on the same `AGSOfflineMapTask`. The overrides are then adjusted so that specific layers will be taken offline using custom settings.

### Streets Basemap (adjust scale range)
In order to minimize the download size for offline map, this sample reduces the scale range for the "World Streets Basemap" layer by adjusting the relevant `AGSExportTileCacheParameters` in the `AGSGenerateOfflineMapParameterOverrides`. The basemap layer is used to contsruct an `AGSOfflineMapParametersKey`object. The key is then used to retrieve the specific `AGSExportTileCacheParameters` for the basemap and the `levelIDs` are updated to skip unwanted levels of detail (based on the values selected in the UI). Note that the original "Streets" basemap is swapped for the "for export" [version of the service](https://www.arcgis.com/home/item.html?id=e384f5aa4eb1433c92afff09500b073d).

### Streets Basemap (buffer extent)
To provide context beyond the study area, the extent for streets basemap is padded. Again, the key for the basemap layer is used to obtain the key and the default extent `AGSGeometry` is retrieved. This extent is then padded (by the distance specified in the UI) using the `class AGSGeometryEngine.bufferGeometry(_:byDistance:)` function and applied to the `AGSExportTileCacheParameters` object.

### System Valves and Service Connections (skip layers)
In this example, the survey is primarily concerned with the Hydrants layer, so other information is not taken offline: this keeps the download smaller and reduces clutter in the offline map. The two layers "System Valves" and "Service Connections" are retrieved from the operational layers list of the map. They are then used to construct an `AGSOfflineMapParametersKey`. This key is used to obtain the relevant `AGSGenerateGeodatabaseParameters` from the `generateGeodatabaseParameters` property of `AGSGenerateOfflineMapParameterOverrides `. The `AGSGenerateLayerOption` for each of the layers is removed from the geodatabse parameters's `layerOptions` by checking the `serviceLayerID`. Note, that you could also choose to download only the schema for these layers by setting the `queryOption` to `.none`.   

### Hydrant Layer (filter features)
Next, the hydrant layer is filtered to exclude certain features. This approach could be taken if the offline map is intended for use with only certain data—for example, where a re-survey is required. To achieve this, a `whereClause` (for example, "FLOW >= 500") needs to be applied to the hydrant's `AGSGenerateLayerOption` in the `AGSGenerateGeodatabaseParameters`. The minimum flow rate value is obtained from the UI setting. The sample constructs a key object from the hydrant layer as in the previous step, and iterates over the available `AGSGenerateGeodatabaseParameters` until the correct one is found and the `AGSGenerateLayerOption` can be updated.

### Water Pipes Dataset (skip geometry filter)
Lastly, the water network dataset is adjusted so that the features are downloaded for the entire dataset, rather than clipped to the area of interest. Again, the key for the layer is constructed using the layer and the relevant `AGSGenerateGeodatabaseParameters` are obtained from the overrides dictionary. The layer options are then adjusted to set `useGeometry` to false.

### Running the job
Having adjusted the `AGSGenerateOfflineMapParameterOverrides` to reflect the custom requirements for the offline map, the original parameters and the custom overrides are used to create a `AGSGenerateOfflineMapJob` object from the offline map task. This job is then started. To provide feedback to the user, the `progress` property of `AGSGenerateOfflineMapJob` is displayed in a sheet. Upon successful completion, the map view is updated with the offline map. 

## Relevant API
- `AGSOfflineMapTask`
- `AGSGenerateGeodatabaseParameters`
- `AGSGenerateOfflineMapParameters`
- `AGSGenerateOfflineMapParameterOverrides`
- `AGSGenerateOfflineMapJob`
- `AGSGenerateOfflineMapResult`
- `AGSExportTileCacheParameters`

## Tags
Offline
