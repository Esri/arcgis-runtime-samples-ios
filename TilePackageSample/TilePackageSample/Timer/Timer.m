// Copyright 2013 ESRI
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

#import "Timer.h"

@implementation Timer

-(id)init {
	self = [super init];
	_result = [NSString stringWithFormat:@"%d",0];
	return self;
}

-(void)start
{
	if(self.timerObj==nil)
		{
		self.startDate =[NSDate date];
		
		self.timerObj=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timer:) userInfo:nil repeats:YES];
		}
	
}

-(void)timer:(NSTimer *)timer
{
	NSInteger secondsSinceStart = (NSInteger)[[NSDate date] timeIntervalSinceDate:self.startDate];
	
	NSInteger seconds = secondsSinceStart % 60;
	NSInteger minutes = (secondsSinceStart / 60) % 60;
	NSInteger hours = secondsSinceStart / (60 * 60);

	if (hours > 0)
		{
		self.result = [NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds];
		}
	else
		{
		self.result = [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
		}
	
	//NSLog(@"time interval -> %@",self.result);
}

-(NSString *)stop
{
	
	if(self.timerObj!=nil)
		{
		self.startDate=nil;
		
		[self.timerObj invalidate];
		self.timerObj = nil;
		}
	return self.result;
}

@end
