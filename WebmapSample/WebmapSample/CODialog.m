//
//  CODialog.m
//  CODialog
//
//  Created by Erik Aigner on 10.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "CODialog.h"


@interface CODialogTextField : UITextField
@property (nonatomic, strong) CODialog *dialog;
@end

@interface CODialogWindowOverlay : UIWindow
@property (nonatomic, strong) CODialog *dialog;
@end

@interface CODialog ()
@property (nonatomic, strong) CODialogWindowOverlay *overlay;
@property (nonatomic, strong) UIWindow *hostWindow;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *accessoryView;
@property (nonatomic, strong) NSMutableArray *textFields;
@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) UIFont *subtitleFont;
@property (nonatomic, assign) NSInteger highlightedIndex;
@end

#define CODialogSynth(x) @synthesize x = x##_;
#define CODialogAssertMQ() NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"%@ must be called on main queue", NSStringFromSelector(_cmd));

#define kCODialogAnimationDuration 0.15
#define kCODialogPopScale 0.5
#define kCODialogPadding 8.0
#define kCODialogFrameInset 8.0
#define kCODialogButtonHeight 44.0
#define kCODialogTextFieldHeight 29.0

@implementation CODialog {
@private
  struct {
    CGRect titleRect;
    CGRect subtitleRect;
    CGRect accessoryRect;
    CGRect textFieldsRect;
    CGRect buttonRect;
  } layout;
}
CODialogSynth(customView)
CODialogSynth(dialogStyle)
CODialogSynth(title)
CODialogSynth(subtitle)
CODialogSynth(batchDelay)
CODialogSynth(overlay)
CODialogSynth(hostWindow)
CODialogSynth(contentView)
CODialogSynth(accessoryView)
CODialogSynth(textFields)
CODialogSynth(buttons)
CODialogSynth(titleFont)
CODialogSynth(subtitleFont)
CODialogSynth(highlightedIndex)

+ (id)dialogWithWindow:(UIWindow *)hostWindow {
  return [[self alloc] initWithWindow:hostWindow];
}

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (id)initWithWindow:(UIWindow *)hostWindow {
    CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
    CGRect insetFrame = CGRectIntegral(CGRectInset(appFrame, 20.0, 20.0));
    insetFrame.size.height = 180.0;
    insetFrame.size.width = 300;
  self = [super initWithFrame:insetFrame];
  if (self) {
    self.batchDelay = 0;
    self.highlightedIndex = -1;
    self.titleFont = [UIFont boldSystemFontOfSize:18.0];
    self.subtitleFont = [UIFont systemFontOfSize:14.0];
    self.hostWindow = hostWindow;
    self.opaque = NO;
    self.alpha = 1.0;
    self.buttons = [NSMutableArray new];
    self.textFields = [NSMutableArray new];
    
    // Register for keyboard notifications
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)adjustToKeyboardBounds:(CGRect)bounds {
  CGRect screenBounds = [[UIScreen mainScreen] bounds];
  CGFloat height = CGRectGetHeight(screenBounds) - CGRectGetHeight(bounds);
  
  CGRect frame = self.frame;
  frame.origin.y = (height - CGRectGetHeight(self.bounds)) / 2.0;
  
  if (CGRectGetMinY(frame) < 0) {
    NSLog(@"warning: dialog is clipped, origin negative (%f)", CGRectGetMinY(frame));
  }
  
  [UIView animateWithDuration:kCODialogAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
    self.frame = frame;
  } completion:^(BOOL finished) {
    // stub
  }];
}

- (void)keyboardWillShow:(NSNotification *)note {
  NSValue *value = [[note userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
  CGRect frame = [value CGRectValue];
  
  [self adjustToKeyboardBounds:frame];
}

- (void)keyboardWillHide:(NSNotification *)note {
  [self adjustToKeyboardBounds:CGRectZero];
}

- (CGRect)defaultDialogFrame {
  CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
  CGRect insetFrame = CGRectIntegral(CGRectInset(appFrame, 20.0, 20.0));
  insetFrame.size.height = 180.0;
  
  return insetFrame;
}

- (void)setProgress:(CGFloat)progress {
  UIProgressView *view = (id)self.accessoryView;
  if ([view isKindOfClass:[UIProgressView class]]) {
    [view setProgress:progress animated:YES];
  }
}

- (CGFloat)progress {
  UIProgressView *view = (id)self.accessoryView;
  if ([view isKindOfClass:[UIProgressView class]]) {
    return view.progress;
  }
  return 0;
}

- (UIView *)makeAccessoryView {
  if (self.dialogStyle == CODialogStyleIndeterminate) {
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityView startAnimating];
    
    return activityView;
  } else if (self.dialogStyle == CODialogStyleDeterminate) {
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progressView.frame = CGRectMake(0, 0, 200.0, 88.0);
    
    return progressView;
  } else if (self.dialogStyle == CODialogStyleSuccess ||
             self.dialogStyle == CODialogStyleError) {
    CGSize iconSize = CGSizeMake(64, 64);
    UIGraphicsBeginImageContextWithOptions(iconSize, NO, 0);
    
    [self drawSymbolInRect:(CGRect){CGPointZero, iconSize}];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
    
    return imageView;
  } else if (self.dialogStyle == CODialogStyleCustomView) {
    return self.customView;
  }
  return nil;
}

- (void)layoutComponents {
  [self setNeedsDisplay];
  
  // Compute frames of components
  CGFloat layoutFrameInset = kCODialogFrameInset + kCODialogPadding;
  CGRect layoutFrame = CGRectInset(self.bounds, layoutFrameInset, layoutFrameInset);
  CGFloat layoutWidth = CGRectGetWidth(layoutFrame);
  
  // Title frame
  CGFloat titleHeight = 0;
  CGFloat minY = CGRectGetMinY(layoutFrame);
  if (self.title.length > 0) {
    titleHeight = [self.title sizeWithFont:self.titleFont
                         constrainedToSize:CGSizeMake(layoutWidth, MAXFLOAT)
                             lineBreakMode:NSLineBreakByWordWrapping].height;
    minY += kCODialogPadding;
  }
  layout.titleRect = CGRectMake(CGRectGetMinX(layoutFrame), minY, layoutWidth, titleHeight);
  
  // Subtitle frame
  CGFloat subtitleHeight = 0;
  minY = CGRectGetMaxY(layout.titleRect);
  if (self.subtitle.length > 0) {
    subtitleHeight = [self.subtitle sizeWithFont:self.subtitleFont
                               constrainedToSize:CGSizeMake(layoutWidth, MAXFLOAT)
                                   lineBreakMode:NSLineBreakByWordWrapping].height;
    minY += kCODialogPadding;
  }
  layout.subtitleRect = CGRectMake(CGRectGetMinX(layoutFrame), minY, layoutWidth, subtitleHeight);
  
  // Accessory frame (note that views are in the content view coordinate system)
  self.accessoryView = [self makeAccessoryView];
  self.accessoryView.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
  
  CGFloat accessoryHeight = 0;
  CGFloat accessoryWidth = CGRectGetWidth(layoutFrame);
  CGFloat accessoryLeft = 0;
  
  minY = CGRectGetMaxY(layout.subtitleRect) - layoutFrameInset;
  
  if (self.accessoryView != nil) {
    accessoryHeight = CGRectGetHeight(self.accessoryView.frame);
    accessoryWidth = CGRectGetWidth(self.accessoryView.frame);
    accessoryLeft = (CGRectGetWidth(layoutFrame) - accessoryWidth) / 2.0;
    minY += kCODialogPadding;
  }
  layout.accessoryRect = CGRectMake(accessoryLeft, minY, accessoryWidth, accessoryHeight);
  
  // Text fields frame (note that views are in the content view coordinate system)
  CGFloat textFieldsHeight = 0;
  NSUInteger numTextFields = self.textFields.count;
  
  minY = CGRectGetMaxY(layout.accessoryRect);
  if (numTextFields > 0) {
    textFieldsHeight = kCODialogTextFieldHeight * (CGFloat)numTextFields + kCODialogPadding * ((CGFloat)numTextFields - 1.0);
    minY += kCODialogPadding;
  }
  layout.textFieldsRect = CGRectMake(CGRectGetMinX(layoutFrame), minY, layoutWidth, textFieldsHeight);
  
  // Buttons frame (note that views are in the content view coordinate system)
  CGFloat buttonsHeight = 0;
  minY = CGRectGetMaxY(layout.textFieldsRect);
  if (self.buttons.count > 0) {
    buttonsHeight = kCODialogButtonHeight;
    minY += kCODialogPadding;
  }
  layout.buttonRect = CGRectMake(CGRectGetMinX(layoutFrame), minY, layoutWidth, buttonsHeight);
  
  // Adjust layout frame
  layoutFrame.size.height = CGRectGetMaxY(layout.buttonRect);
  
  // Create new content view
  UIView *newContentView = [[UIView alloc] initWithFrame:layoutFrame];
  newContentView.contentMode = UIViewContentModeRedraw;
  
  // Layout accessory view
  self.accessoryView.frame = layout.accessoryRect;
  
  [newContentView addSubview:self.accessoryView];
  
  // Layout text fields
  if (numTextFields > 0) {
    for (int i=0; i<numTextFields; i++) {
      CGFloat offsetY = (kCODialogTextFieldHeight + kCODialogPadding) * (CGFloat)i;
      CGRect fieldFrame = CGRectMake(0,
                                     CGRectGetMinY(layout.textFieldsRect) + offsetY,
                                     layoutWidth,
                                     kCODialogTextFieldHeight);
      
      UITextField *field = [self.textFields objectAtIndex:i];
      field.frame = fieldFrame;
      field.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
      
      [newContentView addSubview:field];
    }
  }
  
  // Layout buttons
  NSUInteger count = self.buttons.count;
  if (count > 0) {
    CGFloat buttonWidth = (CGRectGetWidth(layout.buttonRect) - kCODialogPadding * ((CGFloat)count - 1.0)) / (CGFloat)count;
    
    for (int i=0; i<count; i++) {
      CGFloat left = (kCODialogPadding + buttonWidth) * (CGFloat)i;
      CGRect buttonFrame = CGRectIntegral(CGRectMake(left, CGRectGetMinY(layout.buttonRect), buttonWidth, CGRectGetHeight(layout.buttonRect)));
      
      UIButton *button = [self.buttons objectAtIndex:i];
      button.frame = buttonFrame;
      button.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
      
      BOOL highlighted = (self.highlightedIndex == i);
      NSString *title = [button titleForState:UIControlStateNormal];
      
      // Set default image
      UIGraphicsBeginImageContextWithOptions(buttonFrame.size, NO, 0);
      
      [self drawButtonInRect:(CGRect){CGPointZero, buttonFrame.size} title:title highlighted:highlighted down:NO];
      
      [button setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateNormal];
      
      UIGraphicsEndImageContext();
      
      // Set alternate image
      UIGraphicsBeginImageContextWithOptions(buttonFrame.size, NO, 0);
      
      [self drawButtonInRect:(CGRect){CGPointZero, buttonFrame.size} title:title highlighted:NO down:YES];
      [button setImage:UIGraphicsGetImageFromCurrentImageContext() forState:UIControlStateHighlighted];
      
      UIGraphicsEndImageContext();
      
      [newContentView addSubview:button];
    }
  }
  
  // Fade content views
  CGFloat animationDuration = kCODialogAnimationDuration;
  if (self.contentView.superview != nil) {
    [UIView transitionFromView:self.contentView
                        toView:newContentView
                      duration:animationDuration
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    completion:^(BOOL finished) {
                      self.contentView = newContentView;
                    }];
  } else {
    self.contentView = newContentView;
    [self addSubview:newContentView];
    
    // Don't animate frame adjust if there was no content before
    animationDuration = 0;
  }
  
  // Adjust frame size
  [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
    CGRect dialogFrame = CGRectInset(layoutFrame, -kCODialogFrameInset - kCODialogPadding, -kCODialogFrameInset - kCODialogPadding);
    dialogFrame.origin.x = (CGRectGetWidth(self.hostWindow.bounds) - CGRectGetWidth(dialogFrame)) / 2.0;
    dialogFrame.origin.y = (CGRectGetHeight(self.hostWindow.bounds) - CGRectGetHeight(dialogFrame)) / 2.0;
    
    self.frame = CGRectIntegral(dialogFrame);
  } completion:^(BOOL finished) {
    [self setNeedsDisplay];
  }];
}

- (void)resetLayout {
  self.title = nil;
  self.subtitle = nil;
  self.dialogStyle = CODialogStyleDefault;
  self.progress = 0;
  self.customView = nil;
  
  [self removeAllControls];
}

- (void)removeAllControls {
  [self removeAllTextFields];
  [self removeAllButtons];
}

- (void)removeAllTextFields {
  [self.textFields removeAllObjects];
}

- (void)removeAllButtons {
  [self.buttons removeAllObjects];
  self.highlightedIndex = -1;
}

- (void)addTextFieldWithPlaceholder:(NSString *)placeholder secure:(BOOL)secure {
  for (UITextField *field in self.textFields) {
    field.returnKeyType = UIReturnKeyNext;
  }
  
  CODialogTextField *field = [[CODialogTextField alloc] initWithFrame:CGRectMake(0, 0, 200, kCODialogTextFieldHeight)];
  field.dialog = self;
  field.returnKeyType = UIReturnKeyDone;
  field.placeholder = placeholder;
  field.secureTextEntry = secure;
  field.font = [UIFont systemFontOfSize:kCODialogTextFieldHeight - 8.0];
  field.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
  field.textColor = [UIColor blackColor];
  field.keyboardAppearance = UIKeyboardAppearanceAlert;
  field.delegate = (id)self;
  field.autocapitalizationType = UITextAutocapitalizationTypeNone;
  
  [self.textFields addObject:field];
}

- (void)addButtonWithTitle:(NSString *)title target:(id)target selector:(SEL)sel {
  [self addButtonWithTitle:title target:target selector:sel highlighted:NO];
}

- (void)addButtonWithTitle:(NSString *)title target:(id)target selector:(SEL)sel highlighted:(BOOL)flag {
  UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
  
  [button setTitle:title forState:UIControlStateNormal];
  [button addTarget:target action:sel forControlEvents:UIControlEventTouchUpInside];
  
  if (flag) {
    self.highlightedIndex = self.buttons.count;
  }
  
  [self.buttons addObject:button];
}

- (NSString *)textForTextFieldAtIndex:(NSUInteger)index {
  UITextField *field = [self.textFields objectAtIndex:index];
  return [field text];
}

- (void)showOrUpdateAnimatedInternal:(BOOL)flag {

  CODialogWindowOverlay *overlay = self.overlay;
  BOOL show = (overlay == nil);
  
  // Create overlay
  if (show) {
    self.overlay = overlay = [CODialogWindowOverlay new];
    overlay.opaque = NO;
    overlay.windowLevel = UIWindowLevelStatusBar + 1;    
    overlay.dialog = self;
    overlay.frame = self.hostWindow.bounds;
    overlay.alpha = 0.0;
  }
  
  // Layout components
  [self layoutComponents];
  
  if (show) {
    // Scale down ourselves for pop animation
    self.transform = CGAffineTransformMakeScale(kCODialogPopScale, kCODialogPopScale);
    
    // Animate
    NSTimeInterval animationDuration = (flag ? kCODialogAnimationDuration : 0.0);
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
      overlay.alpha = 1.0;
      self.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
      // stub
    }];
    
    [overlay addSubview:self];
    [overlay makeKeyAndVisible];
  }
}

- (void)showOrUpdateAnimated:(BOOL)flag {
  SEL selector = @selector(showOrUpdateAnimatedInternal:);
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:selector object:nil];
  [self performSelector:selector withObject:[NSNumber numberWithBool:flag] afterDelay:self.batchDelay];
}

- (void)hideAnimated:(BOOL)flag {
  
  CODialogWindowOverlay *overlay = self.overlay;
  
  // Nothing to hide if it is not key window
  if (overlay == nil) {
    return;
  }
  
  NSTimeInterval animationDuration = (flag ? kCODialogAnimationDuration : 0.0);
  [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
    overlay.alpha = 0.0;
    self.transform = CGAffineTransformMakeScale(kCODialogPopScale, kCODialogPopScale);
  } completion:^(BOOL finished) {
    overlay.hidden = YES;
    self.transform = CGAffineTransformIdentity;
    [self removeFromSuperview];
    self.overlay = nil;
  }];
}

- (void)hideAnimated:(BOOL)flag afterDelay:(NSTimeInterval)delay {
  
  SEL selector = @selector(hideAnimated:);
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:selector object:nil];
  [self performSelector:selector withObject:[NSNumber numberWithBool:flag] afterDelay:delay];
}

- (void)drawDialogBackgroundInRect:(CGRect)rect {
  // General Declarations
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  // Set alpha
  CGContextSaveGState(context);
  CGContextSetAlpha(context, 0.65);
  
  // Color Declarations
  UIColor *color = [UIColor colorWithRed:0.047 green:0.141 blue:0.329 alpha:1.0];
  
  // Gradient Declarations
  NSArray *gradientColors = [NSArray arrayWithObjects: 
                              (id)[UIColor colorWithWhite:1.0 alpha:0.75].CGColor, 
                              (id)[UIColor colorWithRed:0.227 green:0.310 blue:0.455 alpha:0.8].CGColor, nil];
  CGFloat gradientLocations[] = {0, 1};
  CGGradientRef gradient2 = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
  
  // Abstracted Graphic Attributes
  CGFloat cornerRadius = 8.0;
  CGFloat strokeWidth = 2.0;
  CGColorRef dialogShadow = [UIColor blackColor].CGColor;
  CGSize shadowOffset = CGSizeMake(0, 4);
  CGFloat shadowBlurRadius = kCODialogFrameInset - 2.0;
  
  CGRect frame = CGRectInset(CGRectIntegral(self.bounds), kCODialogFrameInset, kCODialogFrameInset);
  
  // Rounded Rectangle Drawing
  UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:cornerRadius];
  
  CGContextSaveGState(context);
  CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, dialogShadow);
  
  [color setFill];
  [roundedRectanglePath fill];
  
  CGContextRestoreGState(context);
  
  // Set clip path
  [roundedRectanglePath addClip];
  
  // Bezier Drawing
  CGFloat mx = CGRectGetMinX(frame);
  CGFloat my = CGRectGetMinY(frame);
  CGFloat w = CGRectGetWidth(frame);
  CGFloat w2 = w / 2.0;
  CGFloat w4 = w / 4.0;
  CGFloat h1 = 25;
  CGFloat h2 = 35;
  
  UIBezierPath *bezierPath = [UIBezierPath bezierPath];
  [bezierPath moveToPoint:CGPointMake(mx, h1)];
  [bezierPath addCurveToPoint:CGPointMake(mx + w2, h2) controlPoint1:CGPointMake(mx, h1) controlPoint2:CGPointMake(mx + w4, h2)];
  [bezierPath addCurveToPoint:CGPointMake(mx + w, h1) controlPoint1:CGPointMake(mx + w2 + w4, h2) controlPoint2:CGPointMake(mx + w, h1)];
  [bezierPath addCurveToPoint:CGPointMake(mx + w, my) controlPoint1:CGPointMake(mx + w, h1) controlPoint2:CGPointMake(mx + w, my)];
  [bezierPath addCurveToPoint:CGPointMake(mx, my) controlPoint1:CGPointMake(mx + w, my) controlPoint2:CGPointMake(mx, my)];
  [bezierPath addLineToPoint:CGPointMake(mx, h1)];
  [bezierPath closePath];
  
  CGContextSaveGState(context);
  
  [bezierPath addClip];
  
  CGContextDrawLinearGradient(context, gradient2, CGPointMake(w2, 0), CGPointMake(w2, h2), 0);
  CGContextRestoreGState(context);
  
  // Stroke
  [[UIColor whiteColor] setStroke];  
  UIBezierPath *strokePath = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(frame, strokeWidth / 2.0, strokeWidth / 2.0)
                                                        cornerRadius:cornerRadius - strokeWidth / 2.0];
  strokePath.lineWidth = strokeWidth;
  
  [strokePath stroke];
  
  // Cleanup
  CGGradientRelease(gradient2);
  CGColorSpaceRelease(colorSpace);
  CGContextRestoreGState(context);
}

- (void)drawButtonInRect:(CGRect)rect title:(NSString *)title highlighted:(BOOL)highlighted down:(BOOL)down {
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextSaveGState(ctx);
  
  CGFloat radius = 4.0;
  CGFloat strokeWidth = 1.0;
  
  CGRect frame = CGRectIntegral(rect);
  CGRect buttonFrame = CGRectInset(frame, 0, 1);
  
  // Color declarations
  UIColor* whiteTop = [UIColor colorWithWhite:1.0 alpha:0.35];
  UIColor* whiteMiddle = [UIColor colorWithWhite:1.0 alpha:0.10];
  UIColor* whiteBottom = [UIColor colorWithWhite:1.0 alpha:0.0];
  
  // Gradient declarations
  NSArray* gradientColors = [NSArray arrayWithObjects: 
                              (id)whiteTop.CGColor, 
                              (id)whiteMiddle.CGColor, 
                              (id)whiteBottom.CGColor, 
                              (id)whiteBottom.CGColor, nil];
  CGFloat gradientLocations[] = {0, 0.5, 0.5, 1};
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
  CGColorSpaceRelease(colorSpace);
  
  // Bottom shadow
  UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect:buttonFrame cornerRadius:radius];
  
  UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:frame];
  [clipPath appendPath:fillPath];
  [clipPath setUsesEvenOddFillRule:YES];
  
  CGContextSaveGState(ctx);
  
  [clipPath addClip];
  [[UIColor blackColor] setFill];
  
  CGContextSetShadowWithColor(ctx, CGSizeMake(0, 1), 0, [UIColor colorWithWhite:1.0 alpha:0.25].CGColor);
  
  [fillPath fill];
  
  CGContextRestoreGState(ctx);
  
  // Top shadow
  CGContextSaveGState(ctx);
  
  [fillPath addClip];
  [[UIColor blackColor] setFill];
  
  CGContextSetShadowWithColor(ctx, CGSizeMake(0, 2), 0, [UIColor colorWithWhite:1.0 alpha:0.25].CGColor);
  
  [clipPath fill];
  
  CGContextRestoreGState(ctx);
  
  // Button gradient
  CGContextSaveGState(ctx);
  [fillPath addClip];
  
  CGContextDrawLinearGradient(ctx,
                              gradient,
                              CGPointMake(CGRectGetMidX(buttonFrame), CGRectGetMinY(buttonFrame)),
                              CGPointMake(CGRectGetMidX(buttonFrame), CGRectGetMaxY(buttonFrame)), 0);
  CGContextRestoreGState(ctx);
  
  // Draw highlight or down state
  if (highlighted) {
    CGContextSaveGState(ctx);
    
    [[UIColor colorWithWhite:1.0 alpha:0.25] setFill];
    [fillPath fill];
    
    CGContextRestoreGState(ctx);
  } else if (down) {
    CGContextSaveGState(ctx);
    
    [[UIColor colorWithWhite:0.0 alpha:0.25] setFill];
    [fillPath fill];
    
    CGContextRestoreGState(ctx);
  }
  
  // Button stroke
  UIBezierPath *strokePath = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(buttonFrame, strokeWidth / 2.0, strokeWidth / 2.0)
                                                        cornerRadius:radius - strokeWidth / 2.0];
  
  [[UIColor colorWithWhite:0.0 alpha:0.8] setStroke];
  [strokePath stroke];
  
  // Draw title
  CGFloat fontSize = 18.0;
  CGRect textFrame = CGRectIntegral(CGRectMake(0, (CGRectGetHeight(rect) - fontSize) / 2.0 - 1.0, CGRectGetWidth(rect), fontSize));
  
  CGContextSaveGState(ctx);
  CGContextSetShadowWithColor(ctx, CGSizeMake(0.0, -1.0), 0.0, [UIColor blackColor].CGColor);
  
  [[UIColor whiteColor] set];
  [title drawInRect:textFrame withFont:self.titleFont lineBreakMode:NSLineBreakByTruncatingMiddle alignment:NSTextAlignmentCenter];
  
  CGContextRestoreGState(ctx);
  
  // Restore
  CGContextRestoreGState(ctx);
}

- (void)drawTitleInRect:(CGRect)rect isSubtitle:(BOOL)isSubtitle {
  NSString *title = (isSubtitle ? self.subtitle : self.title);
  if (title.length > 0) {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    
    CGContextSetShadowWithColor(ctx, CGSizeMake(0.0, -1.0), 0.0, [UIColor blackColor].CGColor);
    
    UIFont *font = (isSubtitle ? self.subtitleFont : self.titleFont);
    
    [[UIColor whiteColor] set];
    
    [title drawInRect:rect withFont:font lineBreakMode:NSLineBreakByTruncatingMiddle alignment:NSTextAlignmentCenter];
    
    CGContextRestoreGState(ctx);
  }
}

- (void)drawSymbolInRect:(CGRect)rect { 
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  CGContextSaveGState(ctx);
  
  // General Declarations
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  // Color Declarations
  UIColor *grey = [UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0];
  UIColor *black50 = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
  
  // Gradient Declarations
  NSArray *gradientColors = [NSArray arrayWithObjects: 
                             (id)[UIColor whiteColor].CGColor, 
                             (id)grey.CGColor, nil];
  CGFloat gradientLocations[] = {0, 1};
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
  
  // Shadow Declarations
  CGColorRef shadow = black50.CGColor;
  CGSize shadowOffset = CGSizeMake(0, 3);
  CGFloat shadowBlurRadius = 3;
  
  // Bezier Drawing
  UIBezierPath *bezierPath = [UIBezierPath bezierPath];
  if (self.dialogStyle == CODialogStyleSuccess) {
    [bezierPath moveToPoint:CGPointMake(16, 23)];
    [bezierPath addLineToPoint:CGPointMake(27, 34)];
    [bezierPath addLineToPoint:CGPointMake(56, 5)];
    [bezierPath addLineToPoint:CGPointMake(63, 12)];
    [bezierPath addLineToPoint:CGPointMake(27, 48)];
    [bezierPath addLineToPoint:CGPointMake(9, 30)];
    [bezierPath addLineToPoint:CGPointMake(16, 23)];
  } else {
    [bezierPath moveToPoint: CGPointMake(11, 17)];
    [bezierPath addLineToPoint: CGPointMake(19, 9)];
    [bezierPath addLineToPoint: CGPointMake(33, 23)];
    [bezierPath addLineToPoint: CGPointMake(47, 9)];
    [bezierPath addLineToPoint: CGPointMake(55, 17)];
    [bezierPath addLineToPoint: CGPointMake(41, 31)];
    [bezierPath addLineToPoint: CGPointMake(55, 45)];
    [bezierPath addLineToPoint: CGPointMake(47, 53)];
    [bezierPath addLineToPoint: CGPointMake(33, 39)];
    [bezierPath addLineToPoint: CGPointMake(19, 53)];
    [bezierPath addLineToPoint: CGPointMake(11, 45)];
    [bezierPath addLineToPoint: CGPointMake(25, 31)];
    [bezierPath addLineToPoint: CGPointMake(11, 17)];
  }
  
  [bezierPath closePath];
  
  // Determine scale (the default side is 64)
  CGPoint offset = CGPointMake((CGRectGetWidth(rect) - 64.0) / 2.0, (CGRectGetHeight(rect) - 64.0) / 2.0);
  
  [bezierPath applyTransform:CGAffineTransformMakeTranslation(offset.x, offset.y)];
  
  CGContextSaveGState(context);
  CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow);
  CGContextSetFillColorWithColor(context, shadow);
  
  [bezierPath fill];
  [bezierPath addClip];
  
  CGRect bounds = bezierPath.bounds;
  
  CGContextDrawLinearGradient(context,
                              gradient,
                              CGPointMake(CGRectGetMidX(bounds), CGRectGetMinY(bounds)),
                              CGPointMake(CGRectGetMidX(bounds), CGRectGetMaxY(bounds)),
                              0);
  CGContextRestoreGState(context);
  
  // Cleanup
  CGGradientRelease(gradient);
  CGColorSpaceRelease(colorSpace);
  
  CGContextRestoreGState(ctx);
}

- (void)drawTextFieldInRect:(CGRect)rect {
  // General Declarations
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);
  
  // Color Declarations
  UIColor *white10 = [UIColor colorWithWhite:1.0 alpha:0.1];
  UIColor *grey40 = [UIColor colorWithWhite:0.4 alpha:1.0];
  
  // Shadow Declarations
  CGColorRef innerShadow = grey40.CGColor;
  CGSize innerShadowOffset = CGSizeMake(0, 2);
  CGFloat innerShadowBlurRadius = 2;
  CGColorRef outerShadow = white10.CGColor;
  CGSize outerShadowOffset = CGSizeMake(0, 1);
  CGFloat outerShadowBlurRadius = 0;
  
  // Rectangle Drawing
  UIBezierPath *rectanglePath = [UIBezierPath bezierPathWithRect: CGRectIntegral(rect)];
  CGContextSaveGState(context);
  CGContextSetShadowWithColor(context, outerShadowOffset, outerShadowBlurRadius, outerShadow);
  [[UIColor whiteColor] setFill];
  [rectanglePath fill];
  
  // Rectangle Inner Shadow
  CGRect rectangleBorderRect = CGRectInset([rectanglePath bounds], -innerShadowBlurRadius, -innerShadowBlurRadius);
  rectangleBorderRect = CGRectOffset(rectangleBorderRect, -innerShadowOffset.width, -innerShadowOffset.height);
  rectangleBorderRect = CGRectInset(CGRectUnion(rectangleBorderRect, [rectanglePath bounds]), -1, -1);
  
  UIBezierPath* rectangleNegativePath = [UIBezierPath bezierPathWithRect: rectangleBorderRect];
  [rectangleNegativePath appendPath: rectanglePath];
  rectangleNegativePath.usesEvenOddFillRule = YES;
  
  CGContextSaveGState(context);
  {
    CGFloat xOffset = innerShadowOffset.width + round(rectangleBorderRect.size.width);
    CGFloat yOffset = innerShadowOffset.height;
    CGContextSetShadowWithColor(context,
                                CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                innerShadowBlurRadius,
                                innerShadow);
    
    [rectanglePath addClip];
    CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(rectangleBorderRect.size.width), 0);
    [rectangleNegativePath applyTransform: transform];
    [[UIColor grayColor] setFill];
    [rectangleNegativePath fill];
  }
  
  CGContextRestoreGState(context);
  CGContextRestoreGState(context);
  
  [[UIColor blackColor] setStroke];
  rectanglePath.lineWidth = 1;
  [rectanglePath stroke];
  
  CGContextRestoreGState(context);
}

- (void)drawDimmedBackgroundInRect:(CGRect)rect {
  // General Declarations
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  // Color Declarations
  UIColor *greyInner = [UIColor colorWithWhite:0.0 alpha:0.70];
  UIColor *greyOuter = [UIColor colorWithWhite:0.0 alpha:0.2];
  
  // Gradient Declarations
  NSArray* gradientColors = [NSArray arrayWithObjects: 
                             (id)greyOuter.CGColor, 
                             (id)greyInner.CGColor, nil];
  CGFloat gradientLocations[] = {0, 1};
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradientColors, gradientLocations);
  
  // Rectangle Drawing
  CGPoint mid = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
  
  UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect:rect];
  CGContextSaveGState(context);
  [rectanglePath addClip];
  CGContextDrawRadialGradient(context,
                              gradient,
                              mid, 10,
                              mid, CGRectGetMidY(rect),
                              kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
  CGContextRestoreGState(context);
  
  // Cleanup
  CGGradientRelease(gradient);
  CGColorSpaceRelease(colorSpace);
}

- (void)drawRect:(CGRect)rect {
  [self drawDialogBackgroundInRect:rect];
  [self drawTitleInRect:layout.titleRect isSubtitle:NO];
  [self drawTitleInRect:layout.subtitleRect isSubtitle:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  // Cylce through text fields
  NSUInteger index = [self.textFields indexOfObject:textField];
  NSUInteger count = self.textFields.count;
  
  if (index < (count - 1)) {
    UITextField *nextField = [self.textFields objectAtIndex:index + 1];
    [nextField becomeFirstResponder];
  } else {
    [textField resignFirstResponder];
  }
  
  return YES;
}

@end

@implementation CODialogTextField
CODialogSynth(dialog)

- (CGRect)textRectForBounds:(CGRect)bounds {
  return CGRectInset(bounds, 4.0, 4.0);
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
  return [self textRectForBounds:bounds];
}

- (void)drawRect:(CGRect)rect {
  [self.dialog drawTextFieldInRect:rect];
}

@end

@implementation CODialogWindowOverlay
CODialogSynth(dialog)

- (void)drawRect:(CGRect)rect {
  [self.dialog drawDimmedBackgroundInRect:rect];
}

@end
