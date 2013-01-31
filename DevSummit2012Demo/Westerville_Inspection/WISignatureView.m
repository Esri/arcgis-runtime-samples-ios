/*
 WISignatureView.m
 Westerville Inspection Demo -- Esri 2012 Dev Summit
 Copyright © 2012 Esri
 
 All rights reserved under the copyright laws of the United States
 and applicable international laws, treaties, and conventions.
 
 You may freely redistribute and use this sample code, with or
 without modification, provided you include the original copyright
 notice and use restrictions.
 
 See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
 
 */

#import "WISignatureView.h"

@interface WISignatureView () {
@private
    // holds the path representing the signature
    CGMutablePathRef    _path;          
}
@property (nonatomic, strong) UIImage *img;
@end

@implementation WISignatureView

@synthesize img         =_img;
@synthesize lineWidth   =_lineWidth;
@synthesize lineColor   =_lineColor;
@synthesize hasDrawing  = _hasDrawing;

- (void)dealloc {
    UIGraphicsEndImageContext();    
    CGPathRelease(_path);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        // create an image context to draw our signature into
        UIGraphicsBeginImageContextWithOptions(self.bounds.size,NO,0.0);        
        _path = CGPathCreateMutable();
        self.lineColor = [UIColor blackColor];
        self.lineWidth = 3.0f;        
        self.hasDrawing = NO;
    }
    return self;
}

- (void)reset {
    // clear out our path
    self.hasDrawing = NO;
    CGPathRelease(_path);
    _path = CGPathCreateMutable();
    
    // tell our view to redraw
    [self setNeedsDisplay];
}

- (UIImage*)exportSignatureImage {
    // Create our image context and draw the layer into it
    UIGraphicsBeginImageContext(self.bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.layer renderInContext:context];
    UIImage *signatureImage =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext(); 
    
    return signatureImage;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    //
    // get the current context, set our line's properties, add the path
    // to the context, and tell it to draw
    CGContextRef ctxt = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(ctxt, self.lineWidth);
    CGContextSetShouldAntialias(ctxt, YES);
    CGContextSetAllowsAntialiasing(ctxt, YES);
    CGContextSetInterpolationQuality(ctxt, kCGInterpolationHigh);
    CGContextSetStrokeColorWithColor(ctxt, self.lineColor.CGColor);
    CGContextAddPath(ctxt, _path);
    CGContextDrawPath(ctxt, kCGPathStroke);
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // user started signing, get the point and start our new path
    UITouch *touch = [touches anyObject];
    
    // we need the location of the point relative to our bounds
    CGPoint pt = [touch locationInView:self];    
    CGPathMoveToPoint(_path, NULL, pt.x, pt.y);
    
    // redraw
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    self.hasDrawing = YES;
    
    // user is dragging their finger, grab the point and add a line to that
    // point from the current path
    UITouch *touch = [touches anyObject];
    
    // we need the location of the point relative to our bounds
    CGPoint pt = [touch locationInView:self];
    CGPathAddLineToPoint(_path, NULL, pt.x, pt.y);
    
    // redraw
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    // user lifted their finger
    UITouch *touch = [touches anyObject];
    
    // we need the location of the point relative to our bounds
    CGPoint pt = [touch locationInView:self];
    CGPathAddLineToPoint(_path, NULL, pt.x, pt.y);   
    
    // redraw
    [self setNeedsDisplay];  
}
@end
