//
//  NSGraphicsContext.h
//  AppKit-iOS
//
//  Created by Stossy11 on 03/09/2025.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "NSColor.h"

@class NSView;
@class NSWindow;
@class NSImage;

typedef NS_ENUM(NSInteger, NSImageInterpolation) {
    NSImageInterpolationDefault = 0,
    NSImageInterpolationNone = 1,
    NSImageInterpolationLow = 2,
    NSImageInterpolationMedium = 4,
    NSImageInterpolationHigh = 3
};

typedef NS_ENUM(NSInteger, NSCompositingOperation) {
    NSCompositingOperationClear = 0,
    NSCompositingOperationCopy = 1,
    NSCompositingOperationSourceOver = 2,
    NSCompositingOperationSourceIn = 3,
    NSCompositingOperationSourceOut = 4,
    NSCompositingOperationSourceAtop = 5,
    NSCompositingOperationDestinationOver = 6,
    NSCompositingOperationDestinationIn = 7,
    NSCompositingOperationDestinationOut = 8,
    NSCompositingOperationDestinationAtop = 9,
    NSCompositingOperationXOR = 10,
    NSCompositingOperationPlusDarker = 11,
    NSCompositingOperationPlusLighter = 12,
    NSCompositingOperationMultiply = 13,
    NSCompositingOperationScreen = 14,
    NSCompositingOperationOverlay = 15,
    NSCompositingOperationDarken = 16,
    NSCompositingOperationLighten = 17,
    NSCompositingOperationColorDodge = 18,
    NSCompositingOperationColorBurn = 19,
    NSCompositingOperationSoftLight = 20,
    NSCompositingOperationHardLight = 21,
    NSCompositingOperationDifference = 22,
    NSCompositingOperationExclusion = 23,
    NSCompositingOperationHue = 24,
    NSCompositingOperationSaturation = 25,
    NSCompositingOperationColor = 26,
    NSCompositingOperationLuminosity = 27
};


typedef NS_ENUM(NSUInteger, NSBitmapImageFileType) {
    NSBitmapImageFileTypeTIFF,
    NSBitmapImageFileTypeBMP,
    NSBitmapImageFileTypeGIF,
    NSBitmapImageFileTypeJPEG,
    NSBitmapImageFileTypePNG,
    NSBitmapImageFileTypeJPEG2000
};

@interface NSBitmapImageRep : NSObject
@property (nonatomic, readonly) NSInteger pixelsWide;
@property (nonatomic, readonly) NSInteger pixelsHigh;
@property (nonatomic, readonly) NSInteger bitsPerSample;
@property (nonatomic, readonly) NSInteger samplesPerPixel;
@property (nonatomic, readonly) BOOL hasAlpha;
@property (nonatomic, readonly) BOOL isPlanar;
@property (nonatomic, readonly) NSString *colorSpaceName;
@property (nonatomic, readonly) NSInteger bytesPerRow;
@property (nonatomic, readonly) NSInteger bitsPerPixel;
@property (nonatomic, readonly) unsigned char *bitmapData;

- (instancetype)initWithBitmapDataPlanes:(unsigned char **)planes
                              pixelsWide:(NSInteger)width
                              pixelsHigh:(NSInteger)height
                           bitsPerSample:(NSInteger)bps
                         samplesPerPixel:(NSInteger)spp
                                hasAlpha:(BOOL)alpha
                                isPlanar:(BOOL)isPlanar
                          colorSpaceName:(NSString *)colorSpaceName
                             bytesPerRow:(NSInteger)rBytes
                            bitsPerPixel:(NSInteger)pBits;

+ (instancetype)imageRepWithData:(NSData *)data;
- (NSData *)representationUsingType:(NSBitmapImageFileType)storageType properties:(NSDictionary *)properties;

@end



@interface NSGraphicsContext : NSObject

+ (NSGraphicsContext *)currentContext;
+ (void)setCurrentContext:(NSGraphicsContext *)context;
+ (NSGraphicsContext *)graphicsContextWithCGContext:(CGContextRef)cgContext flipped:(BOOL)flipped;
+ (NSGraphicsContext *)graphicsContextWithBitmapImageRep:(NSBitmapImageRep *)bitmapRep;

+ (void)saveGraphicsState;
+ (void)restoreGraphicsState;

@property (nonatomic, readonly) CGContextRef CGContext;
@property (nonatomic, readonly, getter=isFlipped) BOOL flipped;
@property (nonatomic, readonly, getter=isDrawingToScreen) BOOL drawingToScreen;

@property (nonatomic, assign) NSCompositingOperation compositingOperation;
@property (nonatomic, assign) NSImageInterpolation imageInterpolation;
@property (nonatomic, assign) BOOL shouldAntialias;
@property (nonatomic, assign) CGPoint patternPhase;

- (instancetype)initWithCGContext:(CGContextRef)cgContext flipped:(BOOL)flipped;
- (void)saveGraphicsState;
- (void)restoreGraphicsState;
- (void)flushGraphics;
- (BOOL)isFlipped;

@end
