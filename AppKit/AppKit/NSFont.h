//
//  NSFont.h
//  AppKit
//
//  Created by Stossy11 on 25/08/2025.
//


#import <UIKit/UIKit.h>

FOUNDATION_EXPORT NSString * const NSFontAttributeName;
FOUNDATION_EXPORT NSString * const NSForegroundColorAttributeName;
FOUNDATION_EXPORT NSString * const NSBackgroundColorAttributeName;
FOUNDATION_EXPORT NSString * const NSUnderlineStyleAttributeName;
FOUNDATION_EXPORT NSString * const NSStrikethroughStyleAttributeName;

typedef CGFloat NSFontWeight;

FOUNDATION_EXPORT const NSFontWeight NSFontWeightUltraLight;
FOUNDATION_EXPORT const NSFontWeight NSFontWeightThin;
FOUNDATION_EXPORT const NSFontWeight NSFontWeightLight;
FOUNDATION_EXPORT const NSFontWeight NSFontWeightRegular;
FOUNDATION_EXPORT const NSFontWeight NSFontWeightMedium;
FOUNDATION_EXPORT const NSFontWeight NSFontWeightSemibold;
FOUNDATION_EXPORT const NSFontWeight NSFontWeightBold;
FOUNDATION_EXPORT const NSFontWeight NSFontWeightHeavy;
FOUNDATION_EXPORT const NSFontWeight NSFontWeightBlack;

@interface NSFont : UIFont <NSSecureCoding, NSCopying>

@property (nonatomic, readonly) NSString *fontName;
@property (nonatomic, readonly) NSString *familyName;
@property (nonatomic, readonly) CGFloat pointSize;
@property (nonatomic, readonly) CGFloat ascender;
@property (nonatomic, readonly) CGFloat descender;
@property (nonatomic, readonly) CGFloat leading;
@property (nonatomic, readonly) CGFloat capHeight;
@property (nonatomic, readonly) CGFloat xHeight;
@property (nonatomic, readonly) CGFloat lineHeight;
@property (nonatomic, readonly, getter=isBold) BOOL bold;
@property (nonatomic, readonly, getter=isItalic) BOOL italic;


+ (NSFont *)systemFontOfSize:(CGFloat)size;
+ (NSFont *)systemFontOfSize:(CGFloat)size weight:(UIFontWeight)weight;
+ (NSFont *)boldSystemFontOfSize:(CGFloat)size;
+ (NSFont *)italicSystemFontOfSize:(CGFloat)size;
+ (NSFont *)monospacedSystemFontOfSize:(CGFloat)size weight:(UIFontWeight)weight;
+ (NSFont *)fontWithName:(NSString *)fontName size:(CGFloat)size;


+ (NSFont *)userFontOfSize:(CGFloat)size;
+ (NSFont *)messageFontOfSize:(CGFloat)size;
+ (NSFont *)paletteFontOfSize:(CGFloat)size;
+ (NSFont *)labelFontOfSize:(CGFloat)size;
+ (NSFont *)menuFontOfSize:(CGFloat)size;
+ (NSFont *)menuBarFontOfSize:(CGFloat)size;
+ (NSFont *)menuItemFontOfSize:(CGFloat)size;
+ (NSFont *)toolTipsFontOfSize:(CGFloat)size;
+ (NSFont *)controlContentFontOfSize:(CGFloat)size;
+ (NSFont *)titleBarFontOfSize:(CGFloat)size;
+ (NSFont *)windowTitleFontOfSize:(CGFloat)size;
+ (NSFont *)userFixedPitchFontOfSize:(CGFloat)size;

@end