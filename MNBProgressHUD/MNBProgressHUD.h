//
//  MNBProgressHUD.h
//
//  Fork from: https://github.com/JaviSoto/JSProgressHUD
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

enum {
    MNBProgressHUDMaskTypeNone = 1, // allow user interactions while HUD is displayed
    MNBProgressHUDMaskTypeClear, // don't allow
    MNBProgressHUDMaskTypeBlack, // don't allow and dim the UI in the back of the HUD
    MNBProgressHUDMaskTypeGradient // don't allow and dim the UI with a a-la-alert-view bg gradient
};

typedef NSUInteger MNBProgressHUDMaskType;

typedef void (^ShowCompletionCallback) (BOOL finished);
typedef void (^DismissCompletionCallback) (BOOL finished);

@interface MNBProgressHUD : UIView

@property (nonatomic, assign) BOOL ignoreDeviceRotation;
@property (nonatomic, readonly) UIView *overlayView;
@property (nonatomic, assign) CGFloat progressBar;
@property (copy, nonatomic) ShowCompletionCallback showCallback;

+ (MNBProgressHUD *)progressViewInView:(UIView *)view;

- (void)show;
- (void)showWithStatus:(NSString *)status;
- (void)showWithStatus:(NSString *)status maskType:(MNBProgressHUDMaskType)maskType;
- (void)showWithMaskType:(MNBProgressHUDMaskType)maskType;
- (void)showSuccessWithStatus:(NSString *)string;
- (void)setStatus:(NSString *)string; // change the HUD loading status while it's showing
// minube style HUDS
- (void)showMNStyle;
- (void)showMNStyleWithStatus:(NSString *)status;
- (void)showMNStyleWithStatus:(NSString *)string maskType:(MNBProgressHUDMaskType)hudMaskType;
- (void)showMNStyleSuccessMessage:(NSString *)string subtitle:(NSString *)subtitle;
- (void)showMNStyleErrorMessage:(NSString *)string subtitle:(NSString *)subtitle;
- (void)showNoCompletionWithStatus:(NSString *)status subtitle:(NSString *)subtitle;
- (void)showLoadingWithStatus:(NSString *)string subtitle:(NSString *)subtitle;
- (void)showNoPlacesWithStatus:(NSString *)string subtitle:(NSString *)subtitle;
- (void)showUsers:(NSArray *)users withStatus:(NSString *)status afterDelay:(NSTimeInterval)seconds maskType:(MNBProgressHUDMaskType)hudMaskType;

- (void)dismiss; // simply dismiss the HUD with a fade+scale out animation
- (void)dismissWithSuccess:(NSString *)successString; // also displays the success icon image
- (void)dismissWithSuccess:(NSString *)successString afterDelay:(NSTimeInterval)seconds;
- (void)dismissWithError:(NSString *)errorString; // also displays the error icon image
- (void)dismissWithError:(NSString *)errorString afterDelay:(NSTimeInterval)seconds;
// minube style HUDS
- (void)dismissMNStyleWithSuccess:(NSString*)successString subtitle:(NSString *)subtitle;
- (void)dismissMNStyleWithSuccess:(NSString *)successString subtitle:(NSString *)subtitle afterDelay:(NSTimeInterval)seconds;
- (void)dismissMNStyleWithError:(NSString*)errorString subtitle:(NSString *)subtitle;
- (void)dismissMNStyleWithError:(NSString *)errorString subtitle:(NSString *)subtitle afterDelay:(NSTimeInterval)seconds;
- (void)dismissWithLocationError:(NSString *)errorString subtitleError:(NSString *)subtitleError;
- (void)dismissNoPlacesWithStatus:(NSString *)string subtitle:(NSString *)subtitle afterDelay:(NSTimeInterval)seconds;
- (void)dismissWithNetworkError:(NSString *)errorString subtitleError:(NSString *)subtitleError dissmissAnimationFinishedCallback:(DismissCompletionCallback)callback;

@end