##Feature Layer Editing Sample

This sample demonstrates how you can edit geographic data in an ArcGIS Feature service. You can add new features with photo/video as attachment(s), or you can edit and delete existing features. 


![Initial Scene](image.png "Initial Scene")
![Settings](image2.png "Settings")
![Result](image3.png "Result")

###Usage
1. Tap on any location on the map to perform an analysis of areas that could be potentially impacted by hazardous material spill.
2. Change settings such as the wind direction, material type, time or extent of spill to
see how the results change.

###How the sample works
The sample opens a [web map](http://www.arcgis.com/home/item.html?id=b31153c71c6c429a8b24c1751a50d3ad) on www.ArcGIS.com which displays data of 311 Incident calls. The web map also contains popup definitions that describe how information about the 311 incidents should be displayed. When you tap on an incident, the sample uses AGSPopupsContainerViewController to display popup information about that feature in a callout. The popup allows edits to attributes, attachments, or geometry of the feature, and the edits are committed to the service using an AGSFeatureLayer and AGSAttachmentManager.