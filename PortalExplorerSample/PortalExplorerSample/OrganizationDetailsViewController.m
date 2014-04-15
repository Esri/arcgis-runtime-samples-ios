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

#import "OrganizationDetailsViewController.h"


#define kDefaultStyleString @"<style media=\"screen\" type=\"text/css\">html { -webkit-text-size-adjust: none; }</style>"

@interface OrganizationDetailsViewController()

@property (nonatomic, strong) IBOutlet UILabel *nameLabel;
@property (nonatomic, strong) IBOutlet UIWebView *descriptionWebView;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, strong) AGSPortalInfo *portalInfo;

- (void)addShadowToThumbnailImageView;

@end


@implementation OrganizationDetailsViewController

- (id)initWithPortalInfo:(AGSPortalInfo *)portalInfo
{
    self = [super initWithNibName:@"OrganizationDetailsViewController" bundle:nil];
    if (self) {
        self.portalInfo = portalInfo;
    }
    return self;
}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if([[AGSDevice currentDevice] isIPad]){ //ipad   
    
        self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    }
    
    //Use the organization's name if we connected to an organization subscription
    //else, use the portal's name
    self.nameLabel.text = self.portalInfo.organizationId ? self.portalInfo.organizationName : self.portalInfo.portalName; 
    
    //start loading thumbnail
    if (self.portalInfo.organizationThumbnail)
    {
        self.thumbnailImageView.image = self.portalInfo.organizationThumbnail;
    }        
    else if(self.portalInfo.portalThumbnail)
    {
        self.thumbnailImageView.image = self.portalInfo.portalThumbnail;
    }    
    else
    {
        self.thumbnailImageView.image = [UIImage imageNamed:@"defaultOrganization.png"];
    } 
    //add shadow to the thumbnail image. 
    [self addShadowToThumbnailImageView];

    
    //prepare the description
    self.descriptionWebView.hidden = NO; 
    if (self.portalInfo.organizationDescription && [self.portalInfo.organizationDescription length] > 0)
    {
        NSString *styleString = kDefaultStyleString;
        NSString *descriptionWithStyle = [styleString stringByAppendingString:self.portalInfo.organizationDescription];
        
        NSLog(@"%@", descriptionWithStyle);
        [self.descriptionWebView loadHTMLString:descriptionWithStyle baseURL:[NSURL URLWithString:@""]];       
       
    }
    
    else {
        self.descriptionWebView.hidden = YES;
    }    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Helper

- (void)addShadowToThumbnailImageView
{
    if([self.thumbnailImageView.layer respondsToSelector:@selector(setShadowColor:)])
    {
        self.thumbnailImageView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.thumbnailImageView.layer.shadowOpacity = 0.8;
        self.thumbnailImageView.layer.shadowRadius = 5;
        self.thumbnailImageView.layer.shadowOffset = CGSizeMake(5.0f, 5.0f);        
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

-(CGSize)contentSizeForViewInPopover
{
    return self.view.bounds.size;
}

@end
