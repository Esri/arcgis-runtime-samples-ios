# Display feature request mode

Display different feature request modes for a feature table.

![Display feature request mode sample](display-feature-request-mode.png)

## Use case
Feature tables can be initialized with a feature request mode which controls how frequently features are requested and locally cached in response to panning, zooming, selecting, or querying. The appropriate feature request mode can have implications on performance and should be determined based on considerations such as how often the data is expected to change or how often changes in the data should be reflected to the user.


* `ON_INTERACTION_CACHE` - fetches features within the current extent when needed (performing a pan or zoom) from the server and caches those features in a table on the client. Queries will be performed locally if the features are present, otherwise they will be requested from the server. This mode minimizes requests to the server and is useful for large batches of features which will change very infrequently.
* `ON_INTERACTION_NO_CACHE` - always fetches features from the server and doesn't cache any features on the client. This mode is best for features that may change often on the server or whose changes need to always be visible.
* `MANUAL_CACHE` - only fetches features when explicitly populated from a query. This mode is best for features that change minimally or when it is not critical for the user to see the latest changes.

> **NOTE**: **No cache** does not guarantee that features won't be cached locally; feature request mode is a performance concept unrelated to data security.

## How to use the sample

Choose a request mode by tapping the "Mode" button. Pan and zoom to see how the features update at different scales. If you choose `MANUAL_CACHE`, tap the "Populate" button to manually get a cache with a subset of features.

Note: The service limits requests to 1000 features.

## How it works


1. Create an `AGSServiceFeatureTable` with a feature service URL.
2. Set the `featureRequestMode` property of the `AGSServiceFeatureTable` to the desired mode (Cache, No cache, or Manual cache) before the table is loaded.
    * If using `MANUAL_CACHE`, populate the features with `AGSServiceFeatureTable.populateFromService(with:clearCache:outFields:completion:)`.
3. Create an `AGSFeatureLayer` with the feature table and add it to a map's operational layers to display it.

## Relevant API

* AGSFeatureLayer
* AGSFeatureRequestMode
* AGSServiceFeatureTable
* AGSServiceFeatureTable.featureRequestMode
* AGSServiceFeatureTable.populateFromService(with:clearCache:outFields:completion:)

## About the data

This sample uses a service showcasing over 300,000 street trees in Portland, OR. Each tree point models the health of the tree (green - better, red - worse) as well as the diameter of its trunk.

## Tags

cache, data, feature, feature request mode, performance
