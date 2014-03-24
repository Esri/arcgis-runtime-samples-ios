##License Organization Account Sample 

This sample illustrates how you can license your app for Standard level capabilities by allowing a named user to sign into an ArcGIS Online organization account. The sample uses `AGSOAuthLoginViewController` to authenticate the user with ArcGIS Online, and uses `AGSPortal` to connect to the user's account.

The sample shows you how to use the user's account information to license the app for Standard level capabilites. It also shows you how to save the license information in the keychain using `AGSKeychainItemWrapper` and use it when the app shuts down and is restarted. This may be useful, for example, if the app is restarted when the device does not have any network connectivity and the user cannot connect to their account. Using the saved license information allows the app to use  Standard level capabilities for upto 30 days from the last user login.

The sample also shows you how to save the user credential in the keychain so that you can automatically connect to the user's account and refresh the license whenver the app is restarted without requiring the user to authenticate again.



![](image.png)
![](image2.png)
![](image3.png)


