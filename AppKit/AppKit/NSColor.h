//
//  NSColor.h
//  AppKit
//
//  Created by Stossy11 on 25/08/2025.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface NSColor : NSObject <NSSecureCoding, NSCopying>

@property (nonatomic, readonly) UIColor *uiColor;
@property (nonatomic, readonly) CGColorRef CGColor;

- (instancetype)initWithUIColor:(UIColor*)color;

+ (NSColor *)colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a;
+ (NSColor *)colorWithWhite:(CGFloat)w alpha:(CGFloat)a;
+ (NSColor *)colorWithHue:(CGFloat)h saturation:(CGFloat)s brightness:(CGFloat)b alpha:(CGFloat)a;
+ (NSColor *)colorWithCGColor:(CGColorRef)cgColor;

+ (NSColor *)blackColor;
+ (NSColor *)whiteColor;
+ (NSColor *)grayColor;
+ (NSColor *)redColor;
+ (NSColor *)greenColor;
+ (NSColor *)blueColor;
+ (NSColor *)yellowColor;
+ (NSColor *)clearColor;
+ (NSColor *)lightGrayColor;

+ (NSColor *)systemRedColor;
+ (NSColor *)systemGreenColor;
+ (NSColor *)systemBlueColor;
+ (NSColor *)systemYellowColor;
+ (NSColor *)systemOrangeColor;
+ (NSColor *)systemPinkColor;
+ (NSColor *)systemPurpleColor;
+ (NSColor *)systemTealColor;
+ (NSColor *)systemIndigoColor;
+ (NSColor *)systemBrownColor;
+ (NSColor *)systemMintColor;
+ (NSColor *)systemCyanColor;

+ (NSColor *)labelColor;
+ (NSColor *)secondaryLabelColor;
+ (NSColor *)tertiaryLabelColor;
+ (NSColor *)quaternaryLabelColor;

+ (NSColor *)systemBackgroundColor;
+ (NSColor *)secondarySystemBackgroundColor;
+ (NSColor *)tertiarySystemBackgroundColor;
+ (NSColor *)systemGroupedBackgroundColor;
+ (NSColor *)secondarySystemGroupedBackgroundColor;
+ (NSColor *)tertiarySystemGroupedBackgroundColor;

+ (NSColor *)systemFillColor;
+ (NSColor *)secondarySystemFillColor;
+ (NSColor *)tertiarySystemFillColor;
+ (NSColor *)quaternarySystemFillColor;

+ (NSColor *)separatorColor;
+ (NSColor *)opaqueSeparatorColor;
+ (NSColor *)linkColor;
+ (NSColor *)placeholderTextColor;
+ (NSColor *)controlAccentColor;

@property (nonatomic, readonly) CGFloat redComponent;
@property (nonatomic, readonly) CGFloat greenComponent;
@property (nonatomic, readonly) CGFloat blueComponent;
@property (nonatomic, readonly) CGFloat alphaComponent;

- (NSColor *)colorWithAlphaComponent:(CGFloat)alpha;
- (NSColor *)blendedColorWithFraction:(CGFloat)fraction ofColor:(NSColor *)color;

- (UIColor *)resolvedColorWithTraitCollection:(UITraitCollection *)traitCollection API_AVAILABLE(ios(13.0));

+ (NSColor *)colorWithDynamicProvider:(UIColor * (^)(UITraitCollection *))dynamicProvider API_AVAILABLE(ios(13.0));

@end
