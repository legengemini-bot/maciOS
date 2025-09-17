//
//  NSColor.m
//  AppKit
//
//  Created by Stossy11 on 25/08/2025.
//


#import "NSColor.h"
#import <UIKit/UIKit.h>

@implementation NSColor {
    UIColor *_backing;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithUIColor:(UIColor*)c {
    if ((self=[super init])) {
        _backing = c;
    }
    return self;
}

+ (NSColor *)colorWithRed:(CGFloat)r green:(CGFloat)g blue:(CGFloat)b alpha:(CGFloat)a {
    return [[self alloc] initWithUIColor:[UIColor colorWithRed:r green:g blue:b alpha:a]];
}

+ (NSColor *)colorWithWhite:(CGFloat)w alpha:(CGFloat)a {
    return [[self alloc] initWithUIColor:[UIColor colorWithWhite:w alpha:a]];
}

+ (NSColor *)colorWithHue:(CGFloat)h saturation:(CGFloat)s brightness:(CGFloat)b alpha:(CGFloat)a {
    return [[self alloc] initWithUIColor:[UIColor colorWithHue:h saturation:s brightness:b alpha:a]];
}

+ (NSColor *)colorWithCGColor:(CGColorRef)cgColor {
    return [[self alloc] initWithUIColor:[UIColor colorWithCGColor:cgColor]];
}

#define MAKE(name) + (NSColor*)name##Color { return [[self alloc] initWithUIColor:[UIColor name##Color]]; }
MAKE(black)
MAKE(white)
MAKE(gray)
MAKE(red)
MAKE(green)
MAKE(blue)
MAKE(yellow)
MAKE(clear)
#undef MAKE

+ (NSColor *)lightGrayColor;{
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor lightGrayColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor lightGrayColor]];
    }
}


+ (NSColor *)systemRedColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemRedColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor redColor]];
    }
}

+ (NSColor *)systemGreenColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemGreenColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor greenColor]];
    }
}

+ (NSColor *)systemBlueColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemBlueColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor blueColor]];
    }
}

+ (NSColor *)systemYellowColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemYellowColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor yellowColor]];
    }
}

+ (NSColor *)systemOrangeColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemOrangeColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor orangeColor]];
    }
}

+ (NSColor *)systemPinkColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemPinkColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor magentaColor]];
    }
}

+ (NSColor *)systemPurpleColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemPurpleColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor purpleColor]];
    }
}

+ (NSColor *)systemTealColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemTealColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor cyanColor]];
    }
}

+ (NSColor *)systemIndigoColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemIndigoColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor blueColor]];
    }
}

+ (NSColor *)systemBrownColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemBrownColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor brownColor]];
    }
}

+ (NSColor *)systemMintColor {
    if (@available(iOS 15.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemMintColor]];
    } else if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemTealColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor cyanColor]];
    }
}

+ (NSColor *)systemCyanColor {
    if (@available(iOS 15.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemCyanColor]];
    } else if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemTealColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor cyanColor]];
    }
}

+ (NSColor *)labelColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor labelColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor blackColor]];
    }
}

+ (NSColor *)secondaryLabelColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor secondaryLabelColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor grayColor]];
    }
}

+ (NSColor *)tertiaryLabelColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor tertiaryLabelColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor lightGrayColor]];
    }
}

+ (NSColor *)quaternaryLabelColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor quaternaryLabelColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor lightGrayColor]];
    }
}

+ (NSColor *)systemBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemBackgroundColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor whiteColor]];
    }
}

+ (NSColor *)secondarySystemBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor secondarySystemBackgroundColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor lightGrayColor]];
    }
}

+ (NSColor *)tertiarySystemBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor tertiarySystemBackgroundColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor groupTableViewBackgroundColor]];
    }
}

+ (NSColor *)systemGroupedBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemGroupedBackgroundColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor groupTableViewBackgroundColor]];
    }
}

+ (NSColor *)secondarySystemGroupedBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor secondarySystemGroupedBackgroundColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor whiteColor]];
    }
}

+ (NSColor *)tertiarySystemGroupedBackgroundColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor tertiarySystemGroupedBackgroundColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor groupTableViewBackgroundColor]];
    }
}

+ (NSColor *)systemFillColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemFillColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor lightGrayColor]];
    }
}

+ (NSColor *)secondarySystemFillColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor secondarySystemFillColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor lightGrayColor]];
    }
}

+ (NSColor *)tertiarySystemFillColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor tertiarySystemFillColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor lightGrayColor]];
    }
}

+ (NSColor *)quaternarySystemFillColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor quaternarySystemFillColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor lightGrayColor]];
    }
}

+ (NSColor *)separatorColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor separatorColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor lightGrayColor]];
    }
}

+ (NSColor *)opaqueSeparatorColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor opaqueSeparatorColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor grayColor]];
    }
}

+ (NSColor *)linkColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor linkColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor blueColor]];
    }
}

+ (NSColor *)placeholderTextColor {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor placeholderTextColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor lightGrayColor]];
    }
}

+ (NSColor *)controlAccentColor {
    if (@available(iOS 14.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor tintColor]];
    } else if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithUIColor:[UIColor systemBlueColor]];
    } else {
        return [[self alloc] initWithUIColor:[UIColor blueColor]];
    }
}

- (CGColorRef)CGColor {
    return _backing.CGColor;
}

- (UIColor*)uiColor {
    return _backing;
}

- (CGFloat)redComponent {
    CGFloat r,g,b,a;
    [_backing getRed:&r green:&g blue:&b alpha:&a];
    return r;
}

- (CGFloat)greenComponent {
    CGFloat r,g,b,a;
    [_backing getRed:&r green:&g blue:&b alpha:&a];
    return g;
}

- (CGFloat)blueComponent {
    CGFloat r,g,b,a;
    [_backing getRed:&r green:&g blue:&b alpha:&a];
    return b;
}

- (CGFloat)alphaComponent {
    return CGColorGetAlpha(_backing.CGColor);
}

- (NSColor *)colorWithAlphaComponent:(CGFloat)alpha {
    return [[NSColor alloc] initWithUIColor:[_backing colorWithAlphaComponent:alpha]];
}

- (NSColor *)blendedColorWithFraction:(CGFloat)fraction ofColor:(NSColor *)color {
    if (!color) return self;

    CGFloat r1, g1, b1, a1;
    CGFloat r2, g2, b2, a2;

    [_backing getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [color.uiColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];

    CGFloat r = r1 + (r2 - r1) * fraction;
    CGFloat g = g1 + (g2 - g1) * fraction;
    CGFloat b = b1 + (b2 - b1) * fraction;
    CGFloat a = a1 + (a2 - a1) * fraction;

    return [NSColor colorWithRed:r green:g blue:b alpha:a];
}

- (id)copyWithZone:(NSZone*)z {
    return [[NSColor allocWithZone:z] initWithUIColor:_backing];
}

- (void)encodeWithCoder:(NSCoder*)c {
    CGFloat r,g,b,a;
    [_backing getRed:&r green:&g blue:&b alpha:&a];
    [c encodeDouble:r forKey:@"r"];
    [c encodeDouble:g forKey:@"g"];
    [c encodeDouble:b forKey:@"b"];
    [c encodeDouble:a forKey:@"a"];
}

- (instancetype)initWithCoder:(NSCoder*)c {
    return [NSColor colorWithRed:[c decodeDoubleForKey:@"r"]
                           green:[c decodeDoubleForKey:@"g"]
                            blue:[c decodeDoubleForKey:@"b"]
                           alpha:[c decodeDoubleForKey:@"a"]];
}

- (NSString *)description {
    CGFloat r, g, b, a;
    [_backing getRed:&r green:&g blue:&b alpha:&a];
    return [NSString stringWithFormat:@"NSColor(r:%0.3f g:%0.3f b:%0.3f a:%0.3f)", r, g, b, a];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    if (!signature) {
        signature = [_backing methodSignatureForSelector:aSelector];
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if ([_backing respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:_backing];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [super respondsToSelector:aSelector] || [_backing respondsToSelector:aSelector];
}

- (UIColor *)resolvedColorWithTraitCollection:(UITraitCollection *)traitCollection API_AVAILABLE(ios(13.0)) {
    if (@available(iOS 13.0, *)) {
        UIColor *resolved = [_backing resolvedColorWithTraitCollection:traitCollection];
        return resolved;
    }
    return _backing;
}


- (UIColor *)_resolvedBackgroundColorWithTraitCollection:(UITraitCollection *)traitCollection {
    if (@available(iOS 13.0, *)) {
        if ([_backing respondsToSelector:@selector(resolvedColorWithTraitCollection:)]) {
            return [_backing resolvedColorWithTraitCollection:traitCollection];
        }
    }
    return _backing;
}

+ (NSColor *)colorWithDynamicProvider:(UIColor * (^)(UITraitCollection *))dynamicProvider API_AVAILABLE(ios(13.0)) {
    if (@available(iOS 13.0, *)) {
        UIColor *dynamicColor = [UIColor colorWithDynamicProvider:dynamicProvider];
        return [[self alloc] initWithUIColor:dynamicColor];
    } else {

        return [[self alloc] initWithUIColor:dynamicProvider(nil)];
    }
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[NSColor class]]) return NO;

    NSColor *otherColor = (NSColor *)object;
    return [_backing isEqual:otherColor.uiColor];
}

- (NSUInteger)hash {
    return [_backing hash];
}

@end
