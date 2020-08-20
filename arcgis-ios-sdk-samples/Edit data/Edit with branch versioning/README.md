# Edit with branch versioning

Create version and edit features on a service geodatabase.

![Image of edit with branch versioning](editWithBranchVersioning.png)

## Use case

Workflows vary among organizations. They often progress in discrete stages, with each stage requiring the allocation of a different set of resources and business rules. Typically, each stage in the overall process represents a single unit of work, such as a work order or job. To manage these, you can create a separate, isolated version and modify it. Once this work is complete, you can integrate the changes into the default version.

## How to use the sample

Upon opening the sample, it will prompt you for credentials for the service(un: editor01/pwd: editor01.password). Once loaded the map will recenter to the extent of the feature layer. The current version is indicated at the top of the map. Click "Create Version" to open a dialog for you to specify the version information (name, access, and description). The name of the version must meet the following criteria:
1. Must not exceed 62 characters
2. Can not include the following special characters:
    1. Period (.)
    2. Semicolon (;)
    3. Single quotation mark (')
    4. Double quotation mark (")
    5. A space for the first character

Then click "Create" to create the version with the information that you specified. Select a feature to edit an attribute and/or click a second time to relocate the point which will apply the edits to the version you created. Click the button in the top left corner to switch back and forth between the version you created and the default version to see the changes you made.

## How it works

1. Create `ServiceGeodatabase` with the URL to a `FeatureLayer` that has version management enabled and load it.
2. Create `ServiceFeatureTable` from the service geodatabse.
3. Create `FeatureLayer` from the service feature table.
4. Connect to `ServiceGeodatabase::createVersionCompleted` signal to obtain the `ServiceVersionInfo` of the vers
5. Create `ServiceVersionParameters` with a unique name, `AccessVersion`, and description.
    * Note - See the additional information section for more restrictions on the version name.
6. Create new version calling `ServiceGeodatabase::createVersion` passing in the service version parameters.
6. Switch to the version you have just created using `ServiceGeodatabse::switchVersion`, passing in the version name obtained from the service version info from *step 4*.
7. Select a `Feature` from the map and edit it's "TYPDAMAGE" attribute from the options listed in the combo box.
8. Click on the map to relocate the feature.
9. Apply these edits to your version by calling `ServiceGeodatabase::applyEdits()`.
10. Switch back and forth between the your version and the default version to see the edits made to your version.

## Relevant API

* FeatureLayer
* ServiceFeatureTable
* ServiceGedodatabase
* ServiceGeodatabase::applyEdits()
* ServiceGeodatabase::createVersion
* ServiceGeodatabase::createVersionCompleted
* ServiceGeodatabase::switchVersion
* ServiceVersionInfo
* ServiceVersionParameters
* VersionAccess

## About the data

The feature layer used in this sample is [Damage to commercial buildings](https://sampleserver7.arcgisonline.com/arcgis/rest/services/DamageAssessment/FeatureServer/0) located in Naperville Illinois. 

## Additional information

The name of the version must meet the following criteria:
1. Must not exceed 62 characters
2. Can not include the following special characters:
    1. Period (.)
    2. Semicolon (;)
    3. Single quotation mark (')
    4. Double quotation mark (")
    5. A space for the first character

Branch versioning access permission:
1. VersionAccess::Public - Any portal user can view and edit the version.
2. VersionAccess::Protected - Any portal user can view, but only the version owner, feature layer owner, and portal administrator can edit the version.
3. VersionAccess::Private - Only the version owner, feature layer owner, and portal administrator can view and edit the version.

## Tags

branch versioning, edit, reconcile and post, version control, version management server
