/*
 WIContactsManager.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

/*
 Singleton that gives access to list of contacts.
 */

@interface WIContactsManager : NSObject

@property (nonatomic, strong, readonly) NSArray *allContacts;
@property (nonatomic, strong, readonly) NSArray *allContactsWithAddresses;

//class method that returns a singleton object for 
//working with a device's contact list
+ (WIContactsManager *)sharedContactsManager;

// takes in a record's dictionary address, and returns a string
+ (NSString *)stringForAddress:(NSDictionary *)address;

+ (NSString *)nameForRecord:(ABRecordRef)record;

@end
