/* 
 Copyright 2012 Javier Soto (ios@javisoto.es)
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License. 
 */

//
//  MNBProgressHUD.m
//
//  Fork from: https://github.com/JaviSoto/JSProgressHUD
//

#import "MNBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>

@interface MNBProgressHUD ()

@property (nonatomic, readwrite) MNBProgressHUDMaskType maskType;
@property (nonatomic, retain) NSTimer *fadeOutTimer;

@property (nonatomic, readonly) UIView *overlayView;
@property (nonatomic, readonly) UIView *hudView;
@property (nonatomic, readonly) UILabel *stringLabel;
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UIActivityIndicatorView *spinnerView;

@property (nonatomic, readonly) CGFloat visibleKeyboardHeight;

- (void)setStatus:(NSString*)string;
- (void)registerNotifications;
- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle;
- (void)positionHUD:(NSNotification*)notification;

- (void)dismiss;
- (void)dismissWithStatus:(NSString*)string error:(BOOL)error;
- (void)dismissWithStatus:(NSString*)string error:(BOOL)error afterDelay:(NSTimeInterval)seconds;

@end

@implementation MNBProgressHUD

@synthesize overlayView, hudView, maskType, fadeOutTimer, stringLabel, imageView, spinnerView, visibleKeyboardHeight;

+ (MNBProgressHUD *)progressViewInView:(UIView *)view
{	
	MNBProgressHUD *progressView = [[MNBProgressHUD alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [view addSubview:progressView->overlayView];
	
    return [progressView autorelease];
}

- (id)initWithFrame:(CGRect)frame
{	
    if ((self = [super initWithFrame:frame]))
    {
        overlayView = [[UIView alloc] initWithFrame:frame];
        [overlayView addSubview:self];
		self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
		self.alpha = 0;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
	
    return self;
}

#pragma mark - Show Methods

- (void)show
{
	[self showWithStatus:nil];
}

- (void)showWithStatus:(NSString *)status
{
    [self showWithStatus:status maskType:MNBProgressHUDMaskTypeNone];
}

- (void)showWithMaskType:(MNBProgressHUDMaskType)_maskType
{
    [self showWithStatus:nil maskType:_maskType];
}

- (void)showSuccessWithStatus:(NSString *)string
{
    [self show];
    [self dismissWithSuccess:string afterDelay:1];
}

#pragma mark - Dismiss Methods

- (void)dismissWithSuccess:(NSString*)successString
{
	[self dismissWithStatus:successString error:NO];
}

- (void)dismissWithSuccess:(NSString *)successString afterDelay:(NSTimeInterval)seconds
{
    [self dismissWithStatus:successString error:NO afterDelay:seconds];
}

- (void)dismissWithError:(NSString*)errorString
{
	[self dismissWithStatus:errorString error:YES];
}

- (void)dismissWithError:(NSString *)errorString afterDelay:(NSTimeInterval)seconds
{
    [self dismissWithStatus:errorString error:YES afterDelay:seconds];
}

#pragma mark - Instance Methods

- (void)drawRect:(CGRect)rect
{
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    switch (self.maskType) {
            
        case MNBProgressHUDMaskTypeBlack:
        {
            [[UIColor colorWithWhite:0 alpha:0.5] set];
            CGContextFillRect(context, self.bounds);
            break;
        }
            
        case MNBProgressHUDMaskTypeGradient:
        {            
            size_t locationsCount = 2;
            CGFloat locations[2] = {0.0f, 1.0f};
            CGFloat colors[8] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.75f}; 
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
            CGColorSpaceRelease(colorSpace);
            
            CGPoint center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
            float radius = MIN(self.bounds.size.width , self.bounds.size.height) ;
            CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);
            
            break;
        }
    }
}

- (void)setStatus:(NSString *)string
{	
    CGFloat hudWidth = 100;
    CGFloat hudHeight = 100;
    CGFloat stringWidth = 0;
    CGFloat stringHeight = 0;
    CGRect labelRect = CGRectZero;
    
    if (string)
    {
        CGSize stringSize = [string sizeWithFont:self.stringLabel.font constrainedToSize:CGSizeMake(200, 300)];
        stringWidth = stringSize.width;
        stringHeight = stringSize.height;
        hudHeight = 80 + stringHeight;
        
        if (stringWidth > hudWidth)
        {
            hudWidth = ceil(stringWidth / 2) * 2;
        }
        
        if (hudHeight > 100)
        {
            labelRect = CGRectMake(12, 66, hudWidth, stringHeight);
            hudWidth += 24;
        }
        else
        {
            hudWidth += 24;  
            labelRect = CGRectMake(0, 66, hudWidth, stringHeight);   
        }
    }
	
	self.hudView.bounds = CGRectMake(0, 0, hudWidth, hudHeight);
	
	self.imageView.center = CGPointMake(CGRectGetWidth(self.hudView.bounds) / 2, 36);
	
	self.stringLabel.hidden = NO;
	self.stringLabel.text = string;
	self.stringLabel.frame = labelRect;
	
	if (string)
    {
		self.spinnerView.center = CGPointMake(ceil(CGRectGetWidth(self.hudView.bounds) / 2) + 0.5, 40.5);
    }
	else
    {
		self.spinnerView.center = CGPointMake(ceil(CGRectGetWidth(self.hudView.bounds) / 2) + 0.5, ceil(self.hudView.bounds.size.height / 2) + 0.5);
    }
}

- (void)setFadeOutTimer:(NSTimer *)newTimer
{    
    if (fadeOutTimer)
    {      
        [fadeOutTimer invalidate];
        [fadeOutTimer release];
        fadeOutTimer = nil;
    }
    
    if (newTimer)
    {
        fadeOutTimer = [newTimer retain];
    }
}

- (void)registerNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(positionHUD:) 
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification 
                                               object:nil];  
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(positionHUD:) 
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(positionHUD:) 
                                                 name:UIKeyboardDidHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(positionHUD:) 
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(positionHUD:) 
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}

- (void)positionHUD:(NSNotification*)notification
{    
    CGFloat keyboardHeight;
    double animationDuration;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (notification)
    {
        NSDictionary* keyboardInfo = [notification userInfo];
        CGRect keyboardFrame = [[keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        animationDuration = [[keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        
        if (notification.name == UIKeyboardWillShowNotification || notification.name == UIKeyboardDidShowNotification)
        {
            if(UIInterfaceOrientationIsPortrait(orientation))
            {
                keyboardHeight = keyboardFrame.size.height;
            }
            else
            {
                keyboardHeight = keyboardFrame.size.width;
            }
        }
        else
        {
            keyboardHeight = 0;
        }
    }
    else
    {
        keyboardHeight = self.visibleKeyboardHeight;
    }
    
    CGRect orientationFrame = [UIScreen mainScreen].bounds;
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    
    if (UIInterfaceOrientationIsLandscape(orientation))
    {
        float temp = orientationFrame.size.width;
        orientationFrame.size.width = orientationFrame.size.height;
        orientationFrame.size.height = temp;
        
        temp = statusBarFrame.size.width;
        statusBarFrame.size.width = statusBarFrame.size.height;
        statusBarFrame.size.height = temp;
    }
    
    CGFloat activeHeight = orientationFrame.size.height;
    
    if (keyboardHeight > 0)
    {
        activeHeight += statusBarFrame.size.height * 2;
    }
    
    activeHeight -= keyboardHeight;
    CGFloat posY = floor(activeHeight * 0.45);
    CGFloat posX = orientationFrame.size.width / 2;
    
    CGPoint newCenter;
    CGFloat rotateAngle;
    
    switch (orientation)
    { 
        case UIInterfaceOrientationPortraitUpsideDown:
            rotateAngle = M_PI; 
            newCenter = CGPointMake(posX, orientationFrame.size.height - posY);
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rotateAngle = -M_PI / 2.0f;
            newCenter = CGPointMake(posY, posX);
            break;
        case UIInterfaceOrientationLandscapeRight:
            rotateAngle = M_PI / 2.0f;
            newCenter = CGPointMake(orientationFrame.size.height - posY, posX);
            break;
        default: // as UIInterfaceOrientationPortrait
            rotateAngle = 0.0;
            newCenter = CGPointMake(posX, posY);
            break;
    } 
    
    if (notification)
    {
        [UIView animateWithDuration:animationDuration 
                              delay:0 
                            options:UIViewAnimationOptionAllowUserInteraction 
                         animations:^{
                             [self moveToPoint:newCenter rotateAngle:rotateAngle];
                         } completion:NULL];
    } 
    else
    {
        [self moveToPoint:newCenter rotateAngle:rotateAngle];
    }
    
}

- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle
{
    self.hudView.transform = CGAffineTransformMakeRotation(angle); 
    self.hudView.center = newCenter;
}

#pragma mark - Master show/dismiss methods

- (void)showWithStatus:(NSString *)string maskType:(MNBProgressHUDMaskType)hudMaskType
{
	self.fadeOutTimer = nil;
	
	self.imageView.hidden = YES;
    self.maskType = hudMaskType;
	
	[self setStatus:string];
	[self.spinnerView startAnimating];
    
    if (self.maskType != MNBProgressHUDMaskTypeNone)
    {
        self.overlayView.userInteractionEnabled = YES;
    }
    else
    {
        self.overlayView.userInteractionEnabled = NO;
    }
    
    self.overlayView.hidden = NO;
    [self positionHUD:nil];
    
	if (self.alpha != 1)
    {
        [self registerNotifications];
		self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 1.3, 1.3);
		
		[UIView animateWithDuration:0.15
							  delay:0
							options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
						 animations:^{	
							 self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 1/1.3, 1/1.3);
                             self.alpha = 1;
						 }
						 completion:NULL];
	}
    
    [self setNeedsDisplay];
}

- (void)dismissWithStatus:(NSString *)string error:(BOOL)error
{
	[self dismissWithStatus:string error:error afterDelay:0.9];
}

- (void)dismissWithStatus:(NSString *)string error:(BOOL)error afterDelay:(NSTimeInterval)seconds
{
    if (self.alpha != 1)
    {
        return;
    }
	
	if(error)
    {
		self.imageView.image = [UIImage imageNamed:@"MNBProgressHUD.bundle/error.png"];
    }
	else
    {
		self.imageView.image = [UIImage imageNamed:@"MNBProgressHUD.bundle/success.png"];
    }
	
	self.imageView.hidden = NO;
	
	[self setStatus:string];
	
	[self.spinnerView stopAnimating];
    
	self.fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(dismiss) userInfo:nil repeats:NO];
}

- (void)dismiss
{
	[UIView animateWithDuration:0.15
						  delay:0
						options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
					 animations:^{	
						 self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 0.8, 0.8);
						 self.alpha = 0;
					 }
					 completion:^(BOOL finished){ 
                         if (self.alpha == 0) {
                             [[NSNotificationCenter defaultCenter] removeObserver:self];
                             
                             overlayView.hidden = YES;
                         }
                     }];
}

#pragma mark - Getters

- (UIView *)hudView {
    if(!hudView) {
        hudView = [[UIView alloc] initWithFrame:CGRectZero];
        hudView.layer.cornerRadius = 10;
		hudView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        hudView.autoresizingMask = (UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin |
                                    UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin);
        
        [self addSubview:hudView];
    }
    return hudView;
}

- (UILabel *)stringLabel
{
    if (stringLabel == nil)
    {
        stringLabel = [[UILabel alloc] initWithFrame:CGRectZero];
		stringLabel.textColor = [UIColor whiteColor];
		stringLabel.backgroundColor = [UIColor clearColor];
		stringLabel.adjustsFontSizeToFitWidth = YES;
		stringLabel.textAlignment = NSTextAlignmentCenter;
		stringLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		stringLabel.font = [UIFont boldSystemFontOfSize:16];
		stringLabel.shadowColor = [UIColor blackColor];
		stringLabel.shadowOffset = CGSizeMake(0, -1);
        stringLabel.numberOfLines = 0;
		[self.hudView addSubview:stringLabel];
    }
    return stringLabel;
}

- (UIImageView *)imageView
{
    if (imageView == nil)
    {
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
		[self.hudView addSubview:imageView];
    }
    
    return imageView;
}

- (UIActivityIndicatorView *)spinnerView
{
    if (spinnerView == nil)
    {
        spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		spinnerView.hidesWhenStopped = YES;
		spinnerView.bounds = CGRectMake(0, 0, 37, 37);
		[self.hudView addSubview:spinnerView];
    }
    return spinnerView;
}

- (CGFloat)visibleKeyboardHeight
{    
    NSAutoreleasePool *autoreleasePool = [[NSAutoreleasePool alloc] init];
    
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows])
    {
        if(![[testWindow class] isEqual:[UIWindow class]])
        {
            keyboardWindow = testWindow;
            break;
        }
    }

    // Locate UIKeyboard.  
    UIView *foundKeyboard = nil;
    for (UIView *possibleKeyboard in [keyboardWindow subviews]) {
        
        // iOS 4 sticks the UIKeyboard inside a UIPeripheralHostView.
        if ([[possibleKeyboard description] hasPrefix:@"<UIPeripheralHostView"]) {
            possibleKeyboard = [[possibleKeyboard subviews] objectAtIndex:0];
        }                                                                                
        
        if ([[possibleKeyboard description] hasPrefix:@"<UIKeyboard"]) {
            foundKeyboard = possibleKeyboard;
            break;
        }
    }
    
    [autoreleasePool release];
        
    if (foundKeyboard && foundKeyboard.bounds.size.height > 100)
    {
        return foundKeyboard.bounds.size.height;
    }
    
    return 0;
}

#pragma mark - Memory Management

- (void)dealloc
{	
	self.fadeOutTimer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [hudView release];
    [stringLabel release];
    [imageView release];
    [spinnerView release];
    [overlayView release];
    
    [super dealloc];
}

@end
