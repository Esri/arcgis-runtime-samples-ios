//
//  Timer.m
//  MapViewDemo
//
//  Created by Suganya Baskaran on 8/22/13.
//
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
