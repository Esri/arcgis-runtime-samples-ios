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
#import <ArcGIS/ArcGIS.h>

@protocol PortalExplorerDelegate;

@interface PortalExplorer : UIViewController

@property (nonatomic, weak) id <PortalExplorerDelegate> delegate;

//method to instantiate PE with a portal or Organization URL and the credential. 
- (id)initWithURL:(NSURL *)portalURL credential:(AGSCredential *)credential;

//method to update the PE with a credential. 
- (void)updatePortalWithCredential:(AGSCredential *)credential;

@end

/* The delegate methods for the Portal Explorer */
@protocol PortalExplorerDelegate <NSObject>
@required
- (void)portalExplorer:(PortalExplorer *)portalExplorer didLoadPortal:(AGSPortal *)portal;
- (void)portalExplorer:(PortalExplorer *)portalExplorer didFailToLoadPortalWithError:(NSError *)error;
- (void)portalExplorer:(PortalExplorer *)portalExplorer didRequestSignInForPortal:(AGSPortal *)portal;
- (void)portalExplorer:(PortalExplorer *)portalExplorer didRequestSignOutFromPortal:(AGSPortal *)portal;
- (void)portalExplorer:(PortalExplorer *)portalExplorer didSelectPortalItem:(AGSPortalItem *)portalItem;
- (void)portalExplorerWantsToHide:(PortalExplorer *)portalExplorer;


@end