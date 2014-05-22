//
//  MNBProgressHUD.m
//
//  Fork from: https://github.com/samvermette/SVProgressHUD
//

#import "MNBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>

#define kAfterDelay 3.0
#define kHudWidth 250
#define kHudHeight 170
#define kHudHeightOneLine 140

#define iPad    (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define iPhone  (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)

#define createBlockSafeSelf() __block typeof(self) blockSafeSelf = self;

@interface MNBProgressHUD ()
@property (copy, nonatomic) DismissCompletionCallback callback;

@property (nonatomic, readonly) CGFloat visibleKeyboardHeight;

- (void)setStatus:(NSString*)string;
- (void)registerNotifications;
- (void)moveToPoint:(CGPoint)newCenter rotateAngle:(CGFloat)angle;

- (void)dismiss;
- (void)dismissWithStatus:(NSString*)string error:(BOOL)error;
- (void)dismissWithStatus:(NSString*)string error:(BOOL)error afterDelay:(NSTimeInterval)seconds;
- (void)dismissLocalizationErrorWithStatus:(NSString *)string subtitle:(NSString *)subtitle afterDelay:(NSTimeInterval)seconds;
- (void)dismissNetworkErrorWithStatus:(NSString *)string subtitle:(NSString *)subtitle afterDelay:(NSTimeInterval)seconds;

@end

@implementation MNBProgressHUD

@synthesize overlayView, hudView, maskType, fadeOutTimer, stringLabel, subtitleLabel, imageView, spinnerView, visibleKeyboardHeight;
@synthesize loadingView, loadingBarView, progressBar = _progressBar;
@synthesize callback = _callback;
@synthesize showCallback = _showCallback;
@synthesize avatarsContainer;

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
        overlayView.hidden=YES;
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

- (void)showMNStyle
{
	[self showMNStyleWithStatus:nil];
}

- (void)showWithStatus:(NSString *)status
{
    [self showWithStatus:status maskType:MNBProgressHUDMaskTypeNone];
}

- (void)showMNStyleWithStatus:(NSString *)status
{
    [self showMNStyleWithStatus:status maskType:MNBProgressHUDMaskTypeNone];
}

- (void)showNoCompletionWithStatus:(NSString *)status subtitle:(NSString *)subtitle
{
    [self showNoCompletionWithStatus:status subtitle:subtitle afterDelay:kAfterDelay maskType:MNBProgressHUDMaskTypeNone];
}

- (void)showLoadingWithStatus:(NSString *)string subtitle:(NSString *)subtitle
{
    [self showLoadingWithStatus:string subtitle:subtitle maskType:MNBProgressHUDMaskTypeClear];
}

- (void)showWithMaskType:(MNBProgressHUDMaskType)_maskType
{
    [self showWithStatus:nil maskType:_maskType];
}

- (void)showSuccessWithStatus:(NSString *)string
{
    [self show];
    [self dismissWithSuccess:string afterDelay:2];
}

- (void)showNoPlacesWithStatus:(NSString *)string subtitle:(NSString *)subtitle
{
    [self show];
    [self dismissNoPlacesWithStatus:string subtitle:subtitle afterDelay:4];
}

- (void)showMNStyleSuccessMessage:(NSString *)string subtitle:(NSString *)subtitle
{
    [self show];
    [self dismissMNStyleWithSuccess:string subtitle:subtitle afterDelay:kAfterDelay];
}

- (void)showMNStyleErrorMessage:(NSString *)string subtitle:(NSString *)subtitle
{
    [self show];
    [self dismissMNStyleWithError:string subtitle:subtitle afterDelay:kAfterDelay];
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

- (void)dismissMNStyleWithSuccess:(NSString*)successString subtitle:(NSString *)subtitle
{
	[self dismissMNStyleWithStatus:successString subtitle:subtitle error:NO];
}

- (void)dismissMNStyleWithSuccess:(NSString *)successString subtitle:(NSString *)subtitle afterDelay:(NSTimeInterval)seconds
{
    [self dismissMNStyleWithStatus:successString subtitle:subtitle error:NO afterDelay:seconds];
}

- (void)dismissMNStyleWithError:(NSString*)errorString subtitle:(NSString *)subtitle
{
	[self dismissMNStyleWithStatus:errorString subtitle:subtitle error:YES];
}

- (void)dismissMNStyleWithError:(NSString *)errorString subtitle:(NSString *)subtitle afterDelay:(NSTimeInterval)seconds
{
    [self dismissMNStyleWithStatus:errorString subtitle:subtitle error:YES afterDelay:seconds];
}

- (void)dismissWithLocationError:(NSString *)errorString subtitleError:(NSString *)subtitleError
{
    [self dismissLocalizationErrorWithStatus:errorString subtitle:subtitleError afterDelay:kAfterDelay];
}

- (void)dismissWithNetworkError:(NSString *)errorString subtitleError:(NSString *)subtitleError dissmissAnimationFinishedCallback:(DismissCompletionCallback)callback
{
    self.callback = callback;
    
    [self dismissNetworkErrorWithStatus:errorString subtitle:subtitleError afterDelay:kAfterDelay];
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
    if (self.subtitleLabel) {
        self.subtitleLabel.hidden = YES;
    }
    
    if (self.loadingView) {
        self.loadingView.hidden = YES;
    }
    
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

- (void)setMNStyleStatus:(NSString *)string
{
    if (self.subtitleLabel) {
        self.subtitleLabel.hidden = YES;
    }
    
    if (self.loadingView) {
        self.loadingView.hidden = YES;
    }
    
    CGFloat stringWidth = 220;
    CGFloat stringHeight = 40;
    CGRect labelRect = CGRectZero;
    
    if (string)
    {
        CGFloat originX = (kHudWidth / 2) - (stringWidth / 2);
        labelRect = CGRectMake(originX, 105, stringWidth, stringHeight);
    }
	
	self.hudView.bounds = CGRectMake(0, 0, kHudWidth, kHudHeight);
	
	self.imageView.center = CGPointMake(CGRectGetWidth(self.hudView.bounds) / 2, 36);
	
	self.stringLabel.hidden = NO;
	self.stringLabel.text = string;
	self.stringLabel.frame = labelRect;
	
	if (string)
    {
		self.spinnerView.center = CGPointMake(ceil(CGRectGetWidth(self.hudView.bounds) / 2), 65);
    }
	else
    {
		self.spinnerView.center = CGPointMake(ceil(CGRectGetWidth(self.hudView.bounds) / 2) + 0.5, ceil(self.hudView.bounds.size.height / 2) + 0.5);
    }
    
    //DebugLog(@"Frame despues del setStatus");
    //LogFrame(self.hudView.frame);
}

- (void)setStatus:(NSString *)string subtitle:(NSString *)subtitle
{
    if (self.loadingView) {
        self.loadingView.hidden = YES;
    }
    
    CGFloat stringWidth = 220;
    CGFloat stringHeight = 40;
    CGRect labelRect = CGRectZero;
    
    if (subtitle && ![subtitle isEqualToString:@""]) {
        self.hudView.bounds = CGRectMake(0, 0, kHudWidth, kHudHeight);
    } else {
        self.hudView.bounds = CGRectMake(0, 0, kHudWidth, kHudHeightOneLine);
    }
    self.imageView.center = CGPointMake(CGRectGetWidth(self.hudView.bounds) / 2, 45);
    
    if (string)
    {
        CGFloat originX = (kHudWidth / 2) - (stringWidth / 2);
        labelRect = CGRectMake(originX, 80, stringWidth, stringHeight);
    }
    
    self.stringLabel.hidden = NO;
	self.stringLabel.text = string;
	self.stringLabel.frame = labelRect;
    
    stringWidth = 240;
    stringHeight = 20;
    if (subtitle && ![subtitle isEqualToString:@""]) {
        CGFloat originX = (kHudWidth / 2) - (stringWidth / 2);
        labelRect = CGRectMake(originX, 130, stringWidth, stringHeight);
    }
    
    self.subtitleLabel.hidden = NO;
    self.subtitleLabel.text = subtitle;
    self.subtitleLabel.frame = labelRect;
}

- (void)setLoadingViewStatus:(NSString *)string subtitle:(NSString *)subtitle
{
    CGFloat stringWidth = 220;
    CGFloat stringHeight = 40;
    CGRect labelRect = CGRectZero;
    
    self.hudView.bounds = CGRectMake(0, 0, kHudWidth, kHudHeight);
    self.imageView.hidden = YES;
    
    if (string)
    {
        CGFloat originX = (kHudWidth / 2) - (stringWidth / 2);
        labelRect = CGRectMake(originX, 30, stringWidth, stringHeight);
    }
    
    self.stringLabel.hidden = NO;
	self.stringLabel.text = string;
	self.stringLabel.frame = labelRect;
    
    stringWidth = 240;
    stringHeight = 20;
    if (subtitle) {
        CGFloat originX = (kHudWidth / 2) - (stringWidth / 2);
        labelRect = CGRectMake(originX, 82, stringWidth, stringHeight);
    }
    
    self.subtitleLabel.hidden = NO;
    self.subtitleLabel.text = subtitle;
    self.subtitleLabel.frame = labelRect;
    
    self.loadingView.hidden = NO;
    CGFloat originX = (kHudWidth / 2) - (200 / 2);
    self.loadingView.frame = CGRectMake(originX, 120, 200, 17);
    
    UIImageView *loadingBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.loadingView.frame.size.width, self.loadingView.frame.size.height)];
    loadingBackgroundView.image = [UIImage imageNamed:@"progressBarBg"];
    [self.loadingView addSubview:loadingBackgroundView];
    [loadingBackgroundView release];
    
    self.loadingBarView.frame = CGRectMake(- self.loadingView.frame.size.width, 0, self.loadingView.frame.size.width, self.loadingView.frame.size.height);
    [self.loadingView addSubview:loadingBarView];
    
    UIImageView *loadingShadowView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.loadingView.frame.size.width, self.loadingView.frame.size.height)];
    loadingShadowView.image = [UIImage imageNamed:@"progressBarShadow"];
    [self.loadingView addSubview:loadingShadowView];
    [loadingShadowView release];
}

- (void)setProgressBar:(CGFloat)progressBar
{
    createBlockSafeSelf();
    if (self.loadingBarView) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _progressBar = MAX(0, MIN(1, progressBar));
            CGFloat origin = (_progressBar * blockSafeSelf.loadingBarView.frame.size.width) - blockSafeSelf.loadingBarView.frame.size.width;
            CGRect frame = CGRectMake(origin, blockSafeSelf.loadingBarView.frame.origin.y, blockSafeSelf.loadingBarView.frame.size.width, blockSafeSelf.loadingBarView.frame.size.height);
            [UIView animateWithDuration:0.2 animations:^{
                blockSafeSelf.loadingBarView.frame = frame;
            } completion:^(BOOL finished) {
                if (finished)
                {
                    
                }
            }];
        });
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
    CGFloat rotateAngle=0.0;
    
    if (!self.ignoreDeviceRotation) {
        switch (orientation)
        {
            case UIInterfaceOrientationPortraitUpsideDown:
                rotateAngle = M_PI;
                newCenter = CGPointMake(posX, orientationFrame.size.height - posY);
                break;
            case UIInterfaceOrientationLandscapeLeft:
            {
                if (iPhone) {
                    rotateAngle = 0.0;//-M_PI / 2.0f;
                    newCenter = CGPointMake(posX, posY);//CGPointMake(posY, posX);
                }else{
                    rotateAngle = -M_PI / 2.0f;
                    newCenter = CGPointMake(posY, posX);
                }
                
            }
                break;
            case UIInterfaceOrientationLandscapeRight:
            {
                if(iPhone){
                    rotateAngle =  0.0;//M_PI / 2.0f;
                    newCenter = CGPointMake(posX, orientationFrame.size.height - posY);//CGPointMake(orientationFrame.size.height - posY, posX);
                }else{
                    rotateAngle =  M_PI / 2.0f;
                    newCenter = CGPointMake(orientationFrame.size.height - posY, posX);
                }
            }
                break;
            default: // as UIInterfaceOrientationPortrait
                rotateAngle = 0.0;
                newCenter = CGPointMake(posX, posY);
                break;
        }
    }else{
        if (UIInterfaceOrientationIsPortrait(orientation)) {
            newCenter=CGPointMake((orientationFrame.size.height-self.hudView.frame.size.width)/2, (orientationFrame.size.width-self.hudView.frame.size.height)/2);
        }else{
            newCenter=CGPointMake((orientationFrame.size.width-self.hudView.frame.size.width)/2, (orientationFrame.size.height-self.hudView.frame.size.height)/2);
        }
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
    dispatch_async(dispatch_get_main_queue(), ^{
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
        createBlockSafeSelf();
        if (self.alpha != 1)
        {
            [self registerNotifications];
            self.hudView.transform = CGAffineTransformScale(self.hudView.transform, 1.3, 1.3);
            
            [UIView animateWithDuration:0.15
                                  delay:0
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                 blockSafeSelf.hudView.transform = CGAffineTransformScale(blockSafeSelf.hudView.transform, 1/1.3, 1/1.3);
                                 blockSafeSelf.alpha = 1;
                             }
                             completion:^(BOOL finished) {
                                 if(blockSafeSelf.showCallback){
                                     blockSafeSelf.showCallback(finished);
                                     blockSafeSelf.showCallback=nil;
                                 }
                             }];
        }
        
        [self setNeedsDisplay];
    });
}

- (void)showMNStyleWithStatus:(NSString *)string maskType:(MNBProgressHUDMaskType)hudMaskType
{
    dispatch_async(dispatch_get_main_queue(), ^{
        createBlockSafeSelf();
        self.fadeOutTimer = nil;
        
        self.imageView.hidden = YES;
        self.maskType = hudMaskType;
        
        [self setMNStyleStatus:string];
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
                                 blockSafeSelf.hudView.transform = CGAffineTransformScale(blockSafeSelf.hudView.transform, 1/1.3, 1/1.3);
                                 blockSafeSelf.alpha = 1;
                             }
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     if(blockSafeSelf.showCallback){
                                         blockSafeSelf.showCallback(finished);
                                         blockSafeSelf.showCallback=nil;
                                     }
                                 }
                             }];
        }
        
        [self setNeedsDisplay];
    });
}

- (void)showLoadingWithStatus:(NSString *)string subtitle:(NSString *)subtitle maskType:(MNBProgressHUDMaskType)hudMaskType
{
    dispatch_async(dispatch_get_main_queue(), ^{
        createBlockSafeSelf();
        self.fadeOutTimer = nil;
        
        self.imageView.hidden = YES;
        self.maskType = hudMaskType;
        
        [self setLoadingViewStatus:string subtitle:subtitle];
        [self.spinnerView stopAnimating];
        
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
                                 blockSafeSelf.hudView.transform = CGAffineTransformScale(blockSafeSelf.hudView.transform, 1/1.3, 1/1.3);
                                 blockSafeSelf.alpha = 1;
                             }
                             completion:NULL];
        }
        
        [self setNeedsDisplay];
    });
    
}

- (void)showNoCompletionWithStatus:(NSString *)string subtitle:(NSString *)subtitle afterDelay:(NSTimeInterval)seconds maskType:(MNBProgressHUDMaskType)hudMaskType
{
    dispatch_async(dispatch_get_main_queue(), ^{
        createBlockSafeSelf();
        self.fadeOutTimer = nil;
        [self.spinnerView stopAnimating];
        
        self.imageView.image = [UIImage imageNamed:@"msgAlertsIconsExp"];
        self.imageView.hidden = NO;
        
        self.maskType = hudMaskType;
        
        [self setStatus:string subtitle:subtitle];
        
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
                                 blockSafeSelf.hudView.transform = CGAffineTransformScale(blockSafeSelf.hudView.transform, 1/1.3, 1/1.3);
                                 blockSafeSelf.alpha = 1;
                             }
                             completion:^(BOOL finished) {
                                 if (finished) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         blockSafeSelf.fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:blockSafeSelf selector:@selector(dismiss) userInfo:nil repeats:NO];
                                     });
                                     if(blockSafeSelf.showCallback){
                                         blockSafeSelf.showCallback(finished);
                                         blockSafeSelf.showCallback=nil;
                                     }
                                 }
                             }];
        }
        
        [self setNeedsDisplay];
    });
    
}

- (void)dismissWithStatus:(NSString *)string error:(BOOL)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissWithStatus:string error:error afterDelay:kAfterDelay];
    });
}

- (void)dismissWithStatus:(NSString *)string error:(BOOL)error afterDelay:(NSTimeInterval)seconds
{
    createBlockSafeSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        if (blockSafeSelf.alpha != 1)
        {
            return;
        }
        
        if(error)
        {
            blockSafeSelf.imageView.image = [UIImage imageNamed:@"error"];
        }
        else
        {
            blockSafeSelf.imageView.image = [UIImage imageNamed:@"ok"];
        }
        
        blockSafeSelf.imageView.hidden = NO;
        
        [self setStatus:string];
        
        [blockSafeSelf.spinnerView stopAnimating];
        
        blockSafeSelf.fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:blockSafeSelf selector:@selector(dismiss) userInfo:nil repeats:NO];
    });
}

- (void)dismissMNStyleWithStatus:(NSString *)string subtitle:(NSString *)subtitle error:(BOOL)error{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissMNStyleWithStatus:string subtitle:subtitle error:error afterDelay:kAfterDelay];
    });
}

- (void)dismissMNStyleWithStatus:(NSString *)string subtitle:(NSString *)subtitle error:(BOOL)error afterDelay:(NSTimeInterval)seconds
{
    createBlockSafeSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        if (blockSafeSelf.alpha != 1)
        {
            return;
        }
        
        if(error)
        {
            blockSafeSelf.imageView.image = [UIImage imageNamed:@"error"];
        }
        else
        {
            blockSafeSelf.imageView.image = [UIImage imageNamed:@"ok"];
        }
        
        blockSafeSelf.imageView.hidden = NO;
        
        [self setStatus:string subtitle:subtitle];
        
        [blockSafeSelf.spinnerView stopAnimating];
        
        blockSafeSelf.fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:blockSafeSelf selector:@selector(dismiss) userInfo:nil repeats:NO];
    });
}

- (void)dismissLocalizationErrorWithStatus:(NSString *)string subtitle:(NSString *)subtitle afterDelay:(NSTimeInterval)seconds
{
    createBlockSafeSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        if (blockSafeSelf.alpha != 1)
        {
            return;
        }
        
        blockSafeSelf.imageView.image = [UIImage imageNamed:@"msgAlertsIconsLoc"];
        
        blockSafeSelf.imageView.hidden = NO;
        
        [self setStatus:string subtitle:subtitle];
        
        [blockSafeSelf.spinnerView stopAnimating];
        
        blockSafeSelf.fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:blockSafeSelf selector:@selector(dismiss) userInfo:nil repeats:NO];
    });
}

- (void)dismissNetworkErrorWithStatus:(NSString *)string subtitle:(NSString *)subtitle afterDelay:(NSTimeInterval)seconds
{
    createBlockSafeSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        if (blockSafeSelf.alpha != 1)
        {
            return;
        }
        
        blockSafeSelf.imageView.image = [UIImage imageNamed:@"msgAlertsIconsNet"];
        
        blockSafeSelf.imageView.hidden = NO;
        
        [self setStatus:string subtitle:subtitle];
        
        [blockSafeSelf.spinnerView stopAnimating];
        
        blockSafeSelf.fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:blockSafeSelf selector:@selector(dismiss) userInfo:nil repeats:NO];
    });
}

- (void)dismissNoPlacesWithStatus:(NSString *)string subtitle:(NSString *)subtitle afterDelay:(NSTimeInterval)seconds
{
    createBlockSafeSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        if (blockSafeSelf.alpha != 1)
        {
            return;
        }
        
        blockSafeSelf.imageView.image = [UIImage imageNamed:@"cas_icono_guardados"];
        
        blockSafeSelf.imageView.hidden = NO;
        
        [self setStatus:string subtitle:subtitle];
        
        [blockSafeSelf.spinnerView stopAnimating];
        
        blockSafeSelf.fadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:blockSafeSelf selector:@selector(dismiss) userInfo:nil repeats:NO];
    });
}

- (void)dismiss
{
    createBlockSafeSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.15
                              delay:0
                            options:UIViewAnimationCurveEaseIn | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             blockSafeSelf.hudView.transform = CGAffineTransformScale(blockSafeSelf.hudView.transform, 0.8, 0.8);
                             blockSafeSelf.alpha = 0;
                         }
                         completion:^(BOOL finished){
                             if (blockSafeSelf.alpha == 0) {
                                 [[NSNotificationCenter defaultCenter] removeObserver:self];
                                 
                                 overlayView.hidden = YES;
                                 if (blockSafeSelf.callback) {
                                     blockSafeSelf.callback(YES);
                                 }
                             }
                         }];
    });
}

#pragma mark - Getters

- (UIView *)hudView {
    if(!hudView) {
        hudView = [[UIView alloc] initWithFrame:CGRectZero];
        hudView.layer.cornerRadius = 6;
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
		stringLabel.shadowOffset = CGSizeMake(1, 1);
        stringLabel.numberOfLines = 0;
		[self.hudView addSubview:stringLabel];
    }
    return stringLabel;
}

- (UILabel *)subtitleLabel
{
    if (subtitleLabel == nil)
    {
        subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        subtitleLabel.textColor = colorWithRGBA(255, 255, 255, 0.8);
        subtitleLabel.backgroundColor = [UIColor clearColor];
        subtitleLabel.adjustsFontSizeToFitWidth = YES;
        subtitleLabel.textAlignment = NSTextAlignmentCenter;
        subtitleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        subtitleLabel.font = [UIFont systemFontOfSize:13];
        subtitleLabel.shadowColor = [UIColor blackColor];
        subtitleLabel.shadowOffset = CGSizeMake(1, 1);
        subtitleLabel.numberOfLines = 1;
        [self.hudView addSubview:subtitleLabel];
    }
    
    return subtitleLabel;
}

- (UIImageView *)imageView
{
    if (imageView == nil)
    {
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 56, 50)];
        imageView.contentMode = UIViewContentModeCenter;
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

- (UIView *)loadingView
{
    if (loadingView == nil) {
        loadingView = [[UIView alloc] initWithFrame:CGRectZero];
        loadingView.clipsToBounds = YES;
        loadingView.backgroundColor = [UIColor clearColor];
        [[loadingView layer] setCornerRadius:8];
        [self.hudView addSubview:loadingView];
    }
    return loadingView;
}

- (UIView *)loadingBarView
{
    if (loadingBarView == nil) {
        loadingBarView = [[UIView alloc] initWithFrame:CGRectZero];
        loadingBarView.backgroundColor = colorWithRGB(136, 182, 1);
    }
    return loadingBarView;
}

- (UIView *)avatarsContainer
{
    if (avatarsContainer == nil) {
        avatarsContainer = [[UIView alloc] initWithFrame:CGRectZero];
        avatarsContainer.backgroundColor = [UIColor blackColor];
        [self.hudView addSubview:avatarsContainer];
    }
    
    return avatarsContainer;
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
    [stringLabel release];
    [imageView release];
    [spinnerView release];
    [overlayView release];
    [loadingView release];
    [loadingBarView release];
    [_callback release];
    [_showCallback release];
    [avatarsContainer release];
    
    [super dealloc];
}

@end
