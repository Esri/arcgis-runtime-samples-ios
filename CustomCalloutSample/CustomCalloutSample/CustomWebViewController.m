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

#import "CustomWebViewController.h"

@interface CustomWebViewController()

@property (nonatomic, strong) IBOutlet UIWebView *webView;

//this is used for the auto refresh of the web view.
@property (nonatomic, strong) NSTimer *reloadTimer;

- (void)reload;

@end

@implementation CustomWebViewController

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.userInteractionEnabled = NO;
    self.view.alpha = .9;
    [self.webView setScalesPageToFit:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Instance methods

- (void)loadUrlWithRepeatInterval:(NSURL *)url withRepeatInterval:(NSUInteger)interval;
{
    //invalidates the timer.
    [self.reloadTimer invalidate];
    self.reloadTimer = nil;
    
    //loads the url
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    //sets up the timer again for a refresh
    self.reloadTimer = [NSTimer scheduledTimerWithTimeInterval:2 
                                               target:self 
                                             selector:@selector(reload) 
                                             userInfo:nil 
                                              repeats:YES];
    
}

#pragma mark - Helper Methods

- (void)reload 
{
    //reloads the web view. 
    [self.webView reload];
}


@end
