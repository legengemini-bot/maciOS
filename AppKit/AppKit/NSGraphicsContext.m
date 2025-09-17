//
//  NSGraphicsContext.m
//  AppKit-iOS
//
//  Created by Stossy11 on 03/09/2025.
//

#import "NSGraphicsContext.h"

static NSMutableArray<NSGraphicsContext *> *_contextStack = nil;
static NSGraphicsContext *_currentContext = nil;

@interface NSGraphicsContext ()
@property (nonatomic, assign) CGContextRef cgContext;
@property (nonatomic, assign) BOOL flipped;
@property (nonatomic, assign) BOOL ownsContext;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *graphicsStateStack;
@end

@implementation NSGraphicsContext

+ (void)initialize {
    if (self == [NSGraphicsContext class]) {
        _contextStack = [[NSMutableArray alloc] init];
    }
}

+ (NSGraphicsContext *)currentContext {
    return _currentContext;
}

+ (void)setCurrentContext:(NSGraphicsContext *)context {
    _currentContext = context;
    if (context && context.cgContext) {
        UIGraphicsPushContext(context.cgContext);
    }
}

+ (NSGraphicsContext *)graphicsContextWithCGContext:(CGContextRef)cgContext flipped:(BOOL)flipped {
    return [[NSGraphicsContext alloc] initWithCGContext:cgContext flipped:flipped];
}

+ (NSGraphicsContext *)graphicsContextWithBitmapImageRep:(NSBitmapImageRep *)bitmapRep {
    if (!bitmapRep || !bitmapRep.bitmapData) {
        return nil;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    
    if (!bitmapRep.hasAlpha) {
        bitmapInfo = kCGImageAlphaNone;
    }
    
    CGContextRef cgContext = CGBitmapContextCreate(
        bitmapRep.bitmapData,
        bitmapRep.pixelsWide,
        bitmapRep.pixelsHigh,
        bitmapRep.bitsPerSample,
        bitmapRep.bytesPerRow,
        colorSpace,
        bitmapInfo
    );
    
    CGColorSpaceRelease(colorSpace);
    
    if (!cgContext) {
        return nil;
    }
    
    NSGraphicsContext *context = [[NSGraphicsContext alloc] initWithCGContext:cgContext flipped:YES];
    context.ownsContext = YES;
    
    return context;
}

+ (void)saveGraphicsState {
    NSGraphicsContext *current = [self currentContext];
    if (current) {
        [current saveGraphicsState];
        [_contextStack addObject:current];
    }
}

+ (void)restoreGraphicsState {
    if (_contextStack.count > 0) {
        NSGraphicsContext *context = [_contextStack lastObject];
        [context restoreGraphicsState];
        [_contextStack removeLastObject];
        
        if (_contextStack.count > 0) {
            [self setCurrentContext:[_contextStack lastObject]];
        } else {
            [self setCurrentContext:nil];
        }
    }
}

- (instancetype)initWithCGContext:(CGContextRef)cgContext flipped:(BOOL)flipped {
    self = [super init];
    if (self) {
        _cgContext = CGContextRetain(cgContext);
        _flipped = flipped;
        _ownsContext = NO;
        _graphicsStateStack = [[NSMutableArray alloc] init];
        
        _compositingOperation = NSCompositingOperationSourceOver;
        _imageInterpolation = NSImageInterpolationDefault;
        _shouldAntialias = YES;
        _patternPhase = CGPointZero;
        
        [self _applyGraphicsState];
    }
    return self;
}

- (void)dealloc {
    if (_cgContext) {
        CGContextRelease(_cgContext);
        _cgContext = NULL;
    }
}

- (CGContextRef)CGContext {
    return _cgContext;
}

- (BOOL)isDrawingToScreen {
    return NO;
}

- (void)saveGraphicsState {
    if (!_cgContext) return;
    
    CGContextSaveGState(_cgContext);
    
    NSDictionary *state = @{
        @"compositingOperation": @(_compositingOperation),
        @"imageInterpolation": @(_imageInterpolation),
        @"shouldAntialias": @(_shouldAntialias),
        @"patternPhase": [NSValue valueWithCGPoint:_patternPhase]
    };
    
    [_graphicsStateStack addObject:state];
}

- (void)restoreGraphicsState {
    if (!_cgContext) return;
    
    CGContextRestoreGState(_cgContext);
    
    if (_graphicsStateStack.count > 0) {
        NSDictionary *state = [_graphicsStateStack lastObject];
        [_graphicsStateStack removeLastObject];
        
        _compositingOperation = [state[@"compositingOperation"] integerValue];
        _imageInterpolation = [state[@"imageInterpolation"] integerValue];
        _shouldAntialias = [state[@"shouldAntialias"] boolValue];
        _patternPhase = [state[@"patternPhase"] CGPointValue];
        
        [self _applyGraphicsState];
    }
}

- (void)flushGraphics {
    if (_cgContext) {
        CGContextFlush(_cgContext);
    }
}

- (BOOL)isFlipped {
    return _flipped;
}

- (void)setCompositingOperation:(NSCompositingOperation)compositingOperation {
    _compositingOperation = compositingOperation;
    [self _updateBlendMode];
}

- (void)setImageInterpolation:(NSImageInterpolation)imageInterpolation {
    _imageInterpolation = imageInterpolation;
    [self _updateInterpolationQuality];
}

- (void)setShouldAntialias:(BOOL)shouldAntialias {
    _shouldAntialias = shouldAntialias;
    if (_cgContext) {
        CGContextSetShouldAntialias(_cgContext, shouldAntialias);
    }
}

- (void)setPatternPhase:(CGPoint)patternPhase {
    _patternPhase = patternPhase;
    if (_cgContext) {
        CGContextSetPatternPhase(_cgContext, CGSizeMake(patternPhase.x, patternPhase.y));
    }
}

- (void)_applyGraphicsState {
    if (!_cgContext) return;
    
    [self _updateBlendMode];
    [self _updateInterpolationQuality];
    CGContextSetShouldAntialias(_cgContext, _shouldAntialias);
    CGContextSetPatternPhase(_cgContext, CGSizeMake(_patternPhase.x, _patternPhase.y));
}

- (void)_updateBlendMode {
    if (!_cgContext) return;
    
    CGBlendMode blendMode = kCGBlendModeNormal;
    
    switch (_compositingOperation) {
        case NSCompositingOperationClear: blendMode = kCGBlendModeClear; break;
        case NSCompositingOperationCopy: blendMode = kCGBlendModeCopy; break;
        case NSCompositingOperationSourceOver: blendMode = kCGBlendModeNormal; break;
        case NSCompositingOperationSourceIn: blendMode = kCGBlendModeSourceIn; break;
        case NSCompositingOperationSourceOut: blendMode = kCGBlendModeSourceOut; break;
        case NSCompositingOperationSourceAtop: blendMode = kCGBlendModeSourceAtop; break;
        case NSCompositingOperationDestinationOver: blendMode = kCGBlendModeDestinationOver; break;
        case NSCompositingOperationDestinationIn: blendMode = kCGBlendModeDestinationIn; break;
        case NSCompositingOperationDestinationOut: blendMode = kCGBlendModeDestinationOut; break;
        case NSCompositingOperationDestinationAtop: blendMode = kCGBlendModeDestinationAtop; break;
        case NSCompositingOperationXOR: blendMode = kCGBlendModeXOR; break;
        case NSCompositingOperationMultiply: blendMode = kCGBlendModeMultiply; break;
        case NSCompositingOperationScreen: blendMode = kCGBlendModeScreen; break;
        case NSCompositingOperationOverlay: blendMode = kCGBlendModeOverlay; break;
        case NSCompositingOperationDarken: blendMode = kCGBlendModeDarken; break;
        case NSCompositingOperationLighten: blendMode = kCGBlendModeLighten; break;
        case NSCompositingOperationColorDodge: blendMode = kCGBlendModeColorDodge; break;
        case NSCompositingOperationColorBurn: blendMode = kCGBlendModeColorBurn; break;
        case NSCompositingOperationSoftLight: blendMode = kCGBlendModeSoftLight; break;
        case NSCompositingOperationHardLight: blendMode = kCGBlendModeHardLight; break;
        case NSCompositingOperationDifference: blendMode = kCGBlendModeDifference; break;
        case NSCompositingOperationExclusion: blendMode = kCGBlendModeExclusion; break;
        case NSCompositingOperationHue: blendMode = kCGBlendModeHue; break;
        case NSCompositingOperationSaturation: blendMode = kCGBlendModeSaturation; break;
        case NSCompositingOperationColor: blendMode = kCGBlendModeColor; break;
        case NSCompositingOperationLuminosity: blendMode = kCGBlendModeLuminosity; break;
        default: blendMode = kCGBlendModeNormal; break;
    }
    
    CGContextSetBlendMode(_cgContext, blendMode);
}

- (void)_updateInterpolationQuality {
    if (!_cgContext) return;
    
    CGInterpolationQuality quality = kCGInterpolationDefault;
    
    switch (_imageInterpolation) {
        case NSImageInterpolationDefault: quality = kCGInterpolationDefault; break;
        case NSImageInterpolationNone: quality = kCGInterpolationNone; break;
        case NSImageInterpolationLow: quality = kCGInterpolationLow; break;
        case NSImageInterpolationMedium: quality = kCGInterpolationMedium; break;
        case NSImageInterpolationHigh: quality = kCGInterpolationHigh; break;
    }
    
    CGContextSetInterpolationQuality(_cgContext, quality);
}

@end

@interface NSBitmapImageRep ()
@property (nonatomic, assign) NSInteger pixelsWide;
@property (nonatomic, assign) NSInteger pixelsHigh;
@property (nonatomic, assign) NSInteger bitsPerSample;
@property (nonatomic, assign) NSInteger samplesPerPixel;
@property (nonatomic, assign) BOOL hasAlpha;
@property (nonatomic, assign) BOOL isPlanar;
@property (nonatomic, copy) NSString *colorSpaceName;
@property (nonatomic, assign) NSInteger bytesPerRow;
@property (nonatomic, assign) NSInteger bitsPerPixel;
@property (nonatomic, assign) unsigned char *bitmapData;
@property (nonatomic, assign) BOOL ownsData;
@end

@implementation NSBitmapImageRep

- (instancetype)initWithBitmapDataPlanes:(unsigned char **)planes
                              pixelsWide:(NSInteger)width
                              pixelsHigh:(NSInteger)height
                           bitsPerSample:(NSInteger)bps
                         samplesPerPixel:(NSInteger)spp
                                hasAlpha:(BOOL)alpha
                                isPlanar:(BOOL)isPlanar
                          colorSpaceName:(NSString *)colorSpaceName
                             bytesPerRow:(NSInteger)rBytes
                            bitsPerPixel:(NSInteger)pBits {
    self = [super init];
    if (self) {
        _pixelsWide = width;
        _pixelsHigh = height;
        _bitsPerSample = bps;
        _samplesPerPixel = spp;
        _hasAlpha = alpha;
        _isPlanar = isPlanar;
        _colorSpaceName = [colorSpaceName copy];
        _bytesPerRow = rBytes;
        _bitsPerPixel = pBits;
        
        if (planes && planes[0]) {
            _bitmapData = planes[0];
            _ownsData = NO;
        } else {
            NSInteger dataSize = _bytesPerRow * _pixelsHigh;
            _bitmapData = malloc(dataSize);
            _ownsData = YES;
            memset(_bitmapData, 0, dataSize);
        }
    }
    return self;
}

+ (instancetype)imageRepWithData:(NSData *)data {
    if (!data) return nil;
    
    UIImage *uiImage = [UIImage imageWithData:data];
    if (!uiImage) return nil;
    
    CGImageRef cgImage = uiImage.CGImage;
    if (!cgImage) return nil;
    
    NSInteger width = CGImageGetWidth(cgImage);
    NSInteger height = CGImageGetHeight(cgImage);
    NSInteger bitsPerComponent = 8;
    NSInteger samplesPerPixel = 4;
    NSInteger bytesPerRow = width * samplesPerPixel;
    
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:NULL
                      pixelsWide:width
                      pixelsHigh:height
                   bitsPerSample:bitsPerComponent
                 samplesPerPixel:samplesPerPixel
                        hasAlpha:YES
                        isPlanar:NO
                  colorSpaceName:@"NSCalibratedRGBColorSpace"
                     bytesPerRow:bytesPerRow
                    bitsPerPixel:bitsPerComponent * samplesPerPixel];
    
    if (imageRep.bitmapData) {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(
            imageRep.bitmapData, width, height, bitsPerComponent, bytesPerRow,
            colorSpace, kCGImageAlphaPremultipliedLast
        );
        
        if (context) {
            CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
            CGContextRelease(context);
        }
        
        CGColorSpaceRelease(colorSpace);
    }
    
    return imageRep;
}

- (NSData *)representationUsingType:(NSBitmapImageFileType)storageType properties:(NSDictionary *)properties {
    if (!_bitmapData) return nil;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(
        _bitmapData, _pixelsWide, _pixelsHigh, _bitsPerSample, _bytesPerRow,
        colorSpace, _hasAlpha ? kCGImageAlphaPremultipliedLast : kCGImageAlphaNone
    );
    
    CGColorSpaceRelease(colorSpace);
    
    if (!context) return nil;
    
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    if (!cgImage) return nil;
    
    UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    NSData *data = nil;
    switch (storageType) {
        case NSBitmapImageFileTypePNG:
            data = UIImagePNGRepresentation(uiImage);
            break;
        case NSBitmapImageFileTypeJPEG: {
            CGFloat compressionQuality = 0.9;
            if (properties[@"NSImageCompressionFactor"]) {
                compressionQuality = [properties[@"NSImageCompressionFactor"] floatValue];
            }
            data = UIImageJPEGRepresentation(uiImage, compressionQuality);
            break;
        }
        default:
            data = UIImagePNGRepresentation(uiImage);
            break;
    }
    
    return data;
}

- (void)dealloc {
    if (_ownsData && _bitmapData) {
        free(_bitmapData);
        _bitmapData = NULL;
    }
}

@end
