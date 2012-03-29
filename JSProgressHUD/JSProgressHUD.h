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
//  JSProgressHUD.h
//
//  Fork from: https://github.com/samvermette/SVProgressHUD
//

#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

enum {
    JSProgressHUDMaskTypeNone = 1, // allow user interactions while HUD is displayed
    JSProgressHUDMaskTypeClear, // don't allow
    JSProgressHUDMaskTypeBlack, // don't allow and dim the UI in the back of the HUD
    JSProgressHUDMaskTypeGradient // don't allow and dim the UI with a a-la-alert-view bg gradient
};

typedef NSUInteger JSProgressHUDMaskType;

@interface JSProgressHUD : UIView

+ (JSProgressHUD *)progressViewInView:(UIView *)view;

- (void)show;
- (void)showWithStatus:(NSString *)status;
- (void)showWithStatus:(NSString *)status maskType:(JSProgressHUDMaskType)maskType;
- (void)showWithMaskType:(JSProgressHUDMaskType)maskType;

- (void)showSuccessWithStatus:(NSString *)string;
- (void)setStatus:(NSString *)string; // change the HUD loading status while it's showing

- (void)dismiss; // simply dismiss the HUD with a fade+scale out animation
- (void)dismissWithSuccess:(NSString *)successString; // also displays the success icon image
- (void)dismissWithSuccess:(NSString *)successString afterDelay:(NSTimeInterval)seconds;
- (void)dismissWithError:(NSString *)errorString; // also displays the error icon image
- (void)dismissWithError:(NSString *)errorString afterDelay:(NSTimeInterval)seconds;

@end
