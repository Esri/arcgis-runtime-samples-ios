//
//  RecentViewController.h
//  OfflineGeocodingSample
//
//  Created by Divesh Goyal on 8/28/13.
//
//

#import <UIKit/UIKit.h>

@interface RecentViewController : UITableViewController

@property (nonatomic,copy) void (^completionBlock)(NSString*);

- (id)initWithItems:(NSArray*) items;

@end
