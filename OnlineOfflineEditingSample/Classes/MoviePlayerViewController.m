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

#import "MoviePlayerViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation MoviePlayerViewController
@synthesize url = _url;
@synthesize moviePlayer = _moviePlayer;

-(id)initWithURL:(NSURL*)url{
	if (self = [super init]){
		self.url = url;
	}
	return self;
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	// setup the movie player
	self.moviePlayer = [[[MPMoviePlayerController alloc]initWithContentURL:self.url]autorelease];
	 
	self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.moviePlayer.view.autoresizesSubviews = YES;
	
	[self.moviePlayer prepareToPlay];
	
	self.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
	[[self.moviePlayer view] setFrame: [self.view bounds]];  // frame must match parent view
	[self.view addSubview: [self.moviePlayer view]];
	[self.moviePlayer play];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];
	[self.moviePlayer stop];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	self.url = nil;
	self.moviePlayer = nil;
    [super dealloc];
}


@end
