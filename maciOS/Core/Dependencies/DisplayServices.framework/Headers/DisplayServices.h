//
//  DisplayServices.h
//  DisplayServices
//
//  Created by Stossy11 on 24/04/2025.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    kDisplayServiceSuccess = 0,
    kDisplayServiceFailure = -1,
    kDisplayServiceNotSupported = -2
} DisplayServiceStatus;

// iOS-specific screen info structure
typedef struct {
    CGSize resolution;
    CGFloat brightness;
    BOOL isMirrored;
    CGFloat scaleFactor;
} DisplayServiceInfo;

@interface DisplayServices : NSObject

// Get display information for a specific screen
+ (DisplayServiceStatus)getDisplayInfoForScreen:(NSUInteger)screenIndex info:(DisplayServiceInfo *)info;

// Get the number of available displays (for iOS, we'll assume one main display)
+ (NSUInteger)getNumberOfDisplays;

// Set the brightness of the screen (iOS only supports this on the main screen)
+ (DisplayServiceStatus)setDisplayBrightness:(CGFloat)brightness forScreen:(NSUInteger)screenIndex;

// Get the brightness of the screen (iOS only supports this on the main screen)
+ (CGFloat)getDisplayBrightnessForScreen:(NSUInteger)screenIndex;

// Set the display resolution (not supported on iOS, stubbed)
+ (DisplayServiceStatus)setDisplayResolution:(CGSize)resolution forScreen:(NSUInteger)screenIndex;

// Get the display resolution (iOS only supports the main screen)
+ (CGSize)getDisplayResolutionForScreen:(NSUInteger)screenIndex;

// Get the screen scale factor (iOS only supports this for the main screen)
+ (CGFloat)getScreenScaleFactorForScreen:(NSUInteger)screenIndex;

// Get display mirroring status (iOS doesn't have mirroring in the same way, stubbed)
+ (BOOL)isDisplayMirroredForScreen:(NSUInteger)screenIndex;

// Activate display mirroring (not supported on iOS, stubbed)
+ (DisplayServiceStatus)setDisplayMirrored:(BOOL)mirrored forScreen:(NSUInteger)screenIndex;

// Set the display refresh rate (iOS doesn't provide direct API for this, stubbed)
+ (DisplayServiceStatus)setDisplayRefreshRate:(CGFloat)refreshRate forScreen:(NSUInteger)screenIndex;

// Get the display refresh rate (iOS doesn't provide direct API for this, stubbed)
+ (CGFloat)getDisplayRefreshRateForScreen:(NSUInteger)screenIndex;

@end
