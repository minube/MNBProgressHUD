#Intro

This is a lightweight fork from https://github.com/samvermette/SVProgressHUD that simply allows you to create a new instance of a Progress HUD each time and have it as a subview of your controller's view, instead of having a shared view for all controllers.

This prevents the issue where you push another controller while there was a request in progress, that controller also needs a HUD, starts a request, and then the first controller hides the HUD because its request finished, and the second controller loses the HUD even though its request is still in progress.

#Features

- optional loading, success and error status messages.
- automatic positioning based on device type, orientation and keyboard visibility.
- optionally disable user interactions while the HUD is showing with the maskType parameter.

#Usage

```Objective-c
+ (JSProgressHUD *)progressViewInView:(UIView *)view;

- (void)show;
- (void)showWithStatus:(NSString*)status;
- (void)showWithStatus:(NSString*)status maskType:(JSProgressHUDMaskType)maskType;
- (void)showWithMaskType:(JSProgressHUDMaskType)maskType;

- (void)showSuccessWithStatus:(NSString *)string;
- (void)setStatus:(NSString *)string; // change the HUD loading status while it's showing

- (void)dismiss; // simply dismiss the HUD with a fade+scale out animation
- (void)dismissWithSuccess:(NSString *)successString; // also displays the success icon image
- (void)dismissWithSuccess:(NSString *)successString afterDelay:(NSTimeInterval)seconds;
- (void)dismissWithError:(NSString *)errorString; // also displays the error icon image
- (void)dismissWithError:(NSString *)errorString afterDelay:(NSTimeInterval)seconds;
```

#JSProgressHUDMaskType

You can optionally disable user interactions and dim the background UI using the @maskType@ property:

```Objective-c
enum {
    JSProgressHUDMaskTypeNone = 1, // allow user interactions, don't dim background UI (default)
    JSProgressHUDMaskTypeClear, // disable user interactions, don't dim background UI
    JSProgressHUDMaskTypeBlack, // disable user interactions, dim background UI with 50% translucent black
    JSProgressHUDMaskTypeGradient // disable user interactions, dim background UI with translucent radial gradient (a-la-alertView)
};
```

[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/JaviSoto/jsprogresshud/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

