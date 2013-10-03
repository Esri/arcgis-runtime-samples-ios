//
//  Timer.h
//  MapViewDemo
//
//  Created by Suganya Baskaran on 8/22/13.
//
//

#import <Foundation/Foundation.h>

@interface Timer : NSObject
@property (nonatomic,strong) NSTimer *timerObj;
@property (nonatomic,strong) NSDate *startDate;
@property (nonatomic,strong) NSString *result;


-(void)start;
-(NSString *)stop;
@end
