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

#import "PlenaryDemoAppDelegate.h"
#import "PlenaryDemoViewController.h"
#import "ClipboardViewController.h"

@implementation PlenaryDemoAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize clipBoardVC = _clipBoardVC;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    //Make sure for the iPad we use our custom interface
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [window setRootViewController:self.clipBoardVC];

    }
    //and for the iPhone, just use a default viewController that
    //indicates this is really an iPad sample
    else {
    [window setRootViewController:viewController];
    }
    
    [window makeKeyAndVisible];
}




@end
