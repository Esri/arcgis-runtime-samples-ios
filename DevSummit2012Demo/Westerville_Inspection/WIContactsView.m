/*
 WIContactsView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WIContactsView.h"
#import "WIContactGraphic.h"
#import "WIContactsManager.h"
#import "WIDefaultListTableViewCell.h"
#import "WIConstants.h"

@interface WIContactsView () 
{
@private
    NSUInteger _tappedIndex;
}

@property (nonatomic, strong) NSArray           *contacts;
@property (nonatomic, strong) NSMutableArray    *contactGraphics;
@property (nonatomic, strong) AGSLocator        *locator;

@end

@implementation WIContactsView

@synthesize contactDelegate = _contactDelegate;
@synthesize contacts        = _contacts;
@synthesize contactGraphics = _contactGraphics;
@synthesize locator         = _locator;


- (id)initWithFrame:(CGRect)frame withContacts:(NSArray *)contactsList
{
    self = [super initWithFrame:frame listViewTableViewType:AGSListviewTypeStaticTitle datasource:self];
    
    if(self)
    {
        self.contacts = contactsList;
        
        //fill in contact graphics will Null values until they are all located
        self.contactGraphics = [NSMutableArray arrayWithCapacity:3];
        for(int i = 0; i < self.contacts.count; i++)
        {
            [self.contactGraphics addObject:[NSNull null]];
        }
        
        [self setSplashImage:[UIImage imageNamed:@"contacts_splash.png"]];
        
        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

#pragma mark -
#pragma mark AGSListTableViewDataSource
- (NSUInteger)numberOfRows
{
    return self.contacts.count;
}

- (WIListTableViewCell *)listView:(WIListTableView *)tv rowCellForIndex:(NSUInteger)index
{
    WIDefaultListTableViewCell *cell = [tv defaultRowCell];
    
    ABRecordRef currentContact = (__bridge ABRecordRef)[self.contacts objectAtIndex:index];
    cell.nameLabel.text =[WIContactsManager nameForRecord:currentContact];

    return cell;
}

- (NSString *)titleString
{
    return @"Contacts";
}

#pragma mark -
#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    _tappedIndex = indexPath.row;
    
    AGSGraphic *contactGraphic = [self.contactGraphics objectAtIndex:_tappedIndex];
    
    //if we already have graphic for contact, no need to locate it again
    if((NSNull *)contactGraphic != [NSNull null])
    {
        if([self.contactDelegate respondsToSelector:@selector(contactsView:wantsToShowContact:)])
        {
            [self.contactDelegate contactsView:self wantsToShowContact:[self.contactGraphics objectAtIndex:_tappedIndex]];
        }
    }
    //need to locate contact first.  Disable screen here?!
    else 
    {        
        if(_locator == nil)
        {
            self.locator = [AGSLocator locatorWithURL:[NSURL URLWithString:kLocatorServiceURL]];
            self.locator.delegate = self;
        }
        
        ABRecordRef contactRecord = (__bridge ABRecordRef)[self.contacts objectAtIndex:_tappedIndex];
        
        //just grab contact's first address... Could easily be extended to show all of their addresses
        ABMutableMultiValueRef addressMulti = ABRecordCopyValue(contactRecord, kABPersonAddressProperty);
        NSDictionary *firstAddress = (NSDictionary *)CFBridgingRelease(ABMultiValueCopyValueAtIndex(addressMulti, 0));
        NSString *addrString = [WIContactsManager stringForAddress:firstAddress];
        CFRelease(addressMulti);
        CFRelease(CFBridgingRetain(firstAddress));
        
        NSString *currentLocaleString = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
        NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:addrString, @"SingleLine",
                                currentLocaleString, @"localeCode", nil];  
        
        [self.locator locationsForAddress:params
                             returnFields:[NSArray arrayWithObject:@"*"]
                      outSpatialReference:[AGSSpatialReference webMercatorSpatialReference]];
    }
}

#pragma mark -
#pragma mark AGSLocatorDelegate
- (void)locator:(AGSLocator *)locator operation:(NSOperation*)op didFindLocationsForAddress:(NSArray *)candidates
{
    if(candidates.count > 0)
    {
        AGSAddressCandidate *addrCandidate = [candidates objectAtIndex:0];
        AGSPoint *location = [addrCandidate.location copy];
        
        ABRecordRef contactRecord = (__bridge ABRecordRef)[self.contacts objectAtIndex:_tappedIndex];
        NSString *name = [WIContactsManager nameForRecord:contactRecord];
        WIContactGraphic *contactGraphic = [WIContactGraphic contactGraphicWithLocation:location contactName:name];
        
        //add to array
        [self.contactGraphics replaceObjectAtIndex:_tappedIndex withObject:contactGraphic];
        
        if([self.contactDelegate respondsToSelector:@selector(contactsView:wantsToShowContact:)])
        {
            [self.contactDelegate contactsView:self wantsToShowContact:contactGraphic];
        }
    }
    else 
    {
        NSLog(@"Failed to find address!");
    }  
}

- (void)locator:(AGSLocator *)locator operation:(NSOperation*)op didFailLocationsForAddress:(NSError *)error
{
    NSLog(@"Failed to find address!");
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
