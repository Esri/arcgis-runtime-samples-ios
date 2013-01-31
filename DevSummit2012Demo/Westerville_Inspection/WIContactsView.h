/*
 WIContactsView.h
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import <ArcGIS/ArcGIS.h>
#import "WIListTableView.h"

@protocol WIContactsViewDelegate; 

/*
 List view that shows user a selected list of contacts. The user can tap on contacts
 to initiate showing them on the map
 */

@interface WIContactsView : WIListTableView <AGSLocatorDelegate, WIListTableViewDataSource>

@property (nonatomic, unsafe_unretained) id<WIContactsViewDelegate>   contactDelegate;

- (id)initWithFrame:(CGRect)frame withContacts:(NSArray *)contactsList;

@end

@protocol WIContactsViewDelegate <NSObject>

- (void)contactsView:(WIContactsView *)cv wantsToShowContact:(AGSGraphic *)contact;

@end
