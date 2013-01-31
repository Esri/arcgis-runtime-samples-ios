//
//  CODialog.h
//  CODialog
//
//  Created by Erik Aigner on 10.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import <UIKit/UIKit.h>


enum {
  CODialogStyleDefault = 0,
  CODialogStyleIndeterminate,
  CODialogStyleDeterminate,
  CODialogStyleSuccess,
  CODialogStyleError,
  CODialogStyleCustomView
};
typedef NSInteger CODialogStyle;

@interface CODialog : UIView
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, assign) CODialogStyle dialogStyle;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, assign) CGFloat progress;
@property (nonatomic, assign) NSTimeInterval batchDelay;

+ (id)dialogWithWindow:(UIWindow *)hostWindow;

- (id)initWithWindow:(UIWindow *)hostWindow;

/** @name Configuration */

- (void)resetLayout;
- (void)removeAllControls;
- (void)removeAllTextFields;
- (void)removeAllButtons;

- (void)addTextFieldWithPlaceholder:(NSString *)placeholder secure:(BOOL)secure;
- (void)addButtonWithTitle:(NSString *)title target:(id)target selector:(SEL)sel;
- (void)addButtonWithTitle:(NSString *)title target:(id)target selector:(SEL)sel highlighted:(BOOL)flag;

/** @name Getting Values */

- (NSString *)textForTextFieldAtIndex:(NSUInteger)index;

/** @name Showing, Updating and Hiding */

- (void)showOrUpdateAnimated:(BOOL)flag;
- (void)hideAnimated:(BOOL)flag;
- (void)hideAnimated:(BOOL)flag afterDelay:(NSTimeInterval)delay;

/** @name Methods to Override */

- (void)drawRect:(CGRect)rect;
- (void)drawDialogBackgroundInRect:(CGRect)rect;
- (void)drawButtonInRect:(CGRect)rect title:(NSString *)title highlighted:(BOOL)highlighted down:(BOOL)down;
- (void)drawTitleInRect:(CGRect)rect isSubtitle:(BOOL)isSubtitle;
- (void)drawSymbolInRect:(CGRect)rect;
- (void)drawTextFieldInRect:(CGRect)rect;
- (void)drawDimmedBackgroundInRect:(CGRect)rect;

@end
