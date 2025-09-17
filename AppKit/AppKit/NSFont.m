//
//  NSFont.m
//  AppKit
//
//  Created by Stossy11 on 25/08/2025.
//

#import "NSFont.h"

NSString * const NSFontAttributeName = @"NSFont";
NSString * const NSForegroundColorAttributeName = @"NSColor";
NSString * const NSBackgroundColorAttributeName = @"NSBackgroundColor";
NSString * const NSUnderlineStyleAttributeName = @"NSUnderline";
NSString * const NSStrikethroughStyleAttributeName = @"NSStrikethrough";

const NSFontWeight NSFontWeightUltraLight = -0.8;
const NSFontWeight NSFontWeightThin = -0.6;
const NSFontWeight NSFontWeightLight = -0.4;
const NSFontWeight NSFontWeightRegular = 0.0;
const NSFontWeight NSFontWeightMedium = 0.23;
const NSFontWeight NSFontWeightSemibold = 0.3;
const NSFontWeight NSFontWeightBold = 0.4;
const NSFontWeight NSFontWeightHeavy = 0.56;
const NSFontWeight NSFontWeightBlack = 0.62;

@implementation NSFont

+ (BOOL)supportsSecureCoding { return YES; }


+ (NSFont *)systemFontOfSize:(CGFloat)size {
    return (NSFont *)[UIFont systemFontOfSize:size];
}

+ (NSFont *)systemFontOfSize:(CGFloat)size weight:(UIFontWeight)weight {
    if (@available(iOS 8.2, *)) {
        return (NSFont *)[UIFont systemFontOfSize:size weight:weight];
    }
    return [self systemFontOfSize:size];
}

+ (NSFont *)boldSystemFontOfSize:(CGFloat)size {
    return (NSFont *)[UIFont boldSystemFontOfSize:size];
}

+ (NSFont *)italicSystemFontOfSize:(CGFloat)size {
    return (NSFont *)[UIFont italicSystemFontOfSize:size];
}

+ (NSFont *)monospacedSystemFontOfSize:(CGFloat)size weight:(UIFontWeight)weight {
    if (@available(iOS 13.0, *)) {
        return (NSFont *)[UIFont monospacedSystemFontOfSize:size weight:weight];
    }
    UIFont *font = [UIFont fontWithName:@"Courier" size:size];
    return (NSFont *)(font ?: [UIFont systemFontOfSize:size]);
}

+ (NSFont *)fontWithName:(NSString *)name size:(CGFloat)size {
    UIFont *font = [UIFont fontWithName:name size:size];
    return font ? (NSFont *)font : nil;
}


+ (NSFont *)userFontOfSize:(CGFloat)size            { return [self systemFontOfSize:size]; }
+ (NSFont *)messageFontOfSize:(CGFloat)size         { return [self systemFontOfSize:size]; }
+ (NSFont *)paletteFontOfSize:(CGFloat)size         { return [self systemFontOfSize:size]; }
+ (NSFont *)labelFontOfSize:(CGFloat)size           { return [self systemFontOfSize:size]; }
+ (NSFont *)menuFontOfSize:(CGFloat)size            { return [self systemFontOfSize:size]; }
+ (NSFont *)menuBarFontOfSize:(CGFloat)size         { return [self systemFontOfSize:size]; }
+ (NSFont *)menuItemFontOfSize:(CGFloat)size        { return [self systemFontOfSize:size]; }
+ (NSFont *)toolTipsFontOfSize:(CGFloat)size        { return [self systemFontOfSize:size]; }
+ (NSFont *)controlContentFontOfSize:(CGFloat)size  { return [self systemFontOfSize:size]; }
+ (NSFont *)titleBarFontOfSize:(CGFloat)size        { return [self boldSystemFontOfSize:size]; }
+ (NSFont *)windowTitleFontOfSize:(CGFloat)size     { return [self boldSystemFontOfSize:size]; }

+ (NSFont *)userFixedPitchFontOfSize:(CGFloat)size {
    if (@available(iOS 13.0, *)) {
        return (NSFont *)[UIFont monospacedSystemFontOfSize:size weight:UIFontWeightRegular];
    }
    UIFont *font = [UIFont fontWithName:@"Courier" size:size];
    return (NSFont *)(font ?: [UIFont systemFontOfSize:size]);
}


- (BOOL)isBold {
    return self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold;
}

- (BOOL)isItalic {
    return self.fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic;
}


- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.fontName forKey:@"name"];
    [coder encodeDouble:self.pointSize forKey:@"size"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSString *name = [coder decodeObjectOfClass:[NSString class] forKey:@"name"];
    CGFloat size = [coder decodeDoubleForKey:@"size"];
    return [NSFont fontWithName:name size:size];
}

- (id)_primitiveFont {
    return self;
}

@end
