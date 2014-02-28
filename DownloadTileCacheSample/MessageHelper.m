// Copyright 2014 ESRI
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
#import "MessageHelper.h"
#import <ArcGIS/ArcGIS.h>

@implementation MessageHelper

+ (NSString*) extractMostRecentMessage:(NSArray*)messages{
    NSString *description = [[messages objectAtIndex:messages.count-1 ] description];
    NSRange range = [description rangeOfString:@"description:"];
    NSString* message;
    if ( range.length > 0 ) {
        message = [description substringFromIndex:NSMaxRange(range)];
    }else{
        message = description;
    }
    
    if ( messages.count>1) {
        AGSGPMessage *detailsMessages = [messages objectAtIndex:messages.count-2 ];
        NSString* percentageString = detailsMessages.description;
        NSRange range = [percentageString rangeOfString:@"Finished:: "];
        if ( range.length > 0) {
            NSString *substring = [percentageString substringFromIndex:NSMaxRange(range)];
            substring = [substring stringByReplacingOccurrencesOfString:@" percent"
                                                             withString:@""];
            message= [message stringByAppendingFormat:@" (%d%% completed)", [substring intValue]];
        }
    }
    return message;
}





@end
