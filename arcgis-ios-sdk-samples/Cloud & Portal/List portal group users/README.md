#List portal group users

This sample demonstrates how to show the users in a portal group.

![](image1.png)

##How it works

The sample initializes an `AGSPortal` object. A group on this portal is retrieved using the `findGroups(with:completion:)` method. From this group, all users are fetched using the `fetchUsers(completion:)` method. The method returns an array of user names. An `AGSPortalUser` object is created for each user name using the `init(portal:username:)` initializer. Each of these portalUser object is loaded and the user information is shown in a table view.




