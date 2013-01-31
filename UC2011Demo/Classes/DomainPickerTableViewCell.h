// Copyright 2012 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

#import <UIKit/UIKit.h>

/*
 Custom cell for the domain picker. Used to make a table that doesn't
 look a typical tableView 
 */

@interface DomainPickerTableViewCell : UITableViewCell 
{
    UILabel *_domainValue;
    UIImageView *_checkMark;
}

@property (nonatomic, strong) IBOutlet UILabel *domainValue;
@property (nonatomic, strong) IBOutlet UIImageView *checkMark;

@end
