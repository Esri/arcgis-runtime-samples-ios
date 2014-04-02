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

#import "CustomSegue.h"
#import <ArcGIS/ArcGIS.h>

//Custom segue to accomodate different presentation style for iPad and iPhone
@implementation CustomSegue

-(void)perform {
    //in case of iPad present new view as pop over
    if ([[AGSDevice currentDevice] isIPad]) {
        [self.popOverController presentPopoverFromRect:self.rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    //in case of iPhone present view as a modal view
    else {
        [self.sourceViewController presentViewController:[self destinationViewController] animated:YES completion:nil];
    }
}

@end
