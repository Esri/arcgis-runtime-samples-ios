##Asynchronous Geoprocessing Sample 

This sample shows how to  perform analysis using ArcGIS Server Geoprocessing services.

<img src="https://raw.github.com/Esri/arcgis-runtime-samples-ios/master/AsynchronousGPSample/image.png?login=dg0yal&token=f7a4ea724bbe0aa015c60526867f4d84"/>
<img src="https://raw.github.com/Esri/arcgis-runtime-samples-ios/master/AsynchronousGPSample/image.png?login=dg0yal&token=f7a4ea724bbe0aa015c60526867f4d84"/>
<img src="https://raw.github.com/Esri/arcgis-runtime-samples-ios/master/AsynchronousGPSample/image.png?login=dg0yal&token=f7a4ea724bbe0aa015c60526867f4d84"/>


###Instructions to use the sample
1. Tap on any location on the map to perform a spill analysis. The result indicate what
areas could be impacted by the spill.
2. Change settings such as the wind direction, material type, time or extent of spill to
see how the results change.

###How the sample works
The sample uses the  AGSGeoprocessor class in the API to submit a geoprocessing job to the service. The samples uses the Chemical Emergency Resource Guide service (http://sampleserver2.arcgisonline.com/ArcGIS/rest/services/PublicSafety/EMModels/GPServer/ERGByChemical) . Upon submitting the job to the server, a JobID is returned. The geoprocessor periodically polls the server using the JobID to check if the job is completed, and upon completion displays the results on the map.

