//
//  NSImage.m
//  AppKit
//
//  Created by Stossy11 on 25/08/2025.
//

#import "NSImage.h"
#import <CoreServices/CoreServices.h>

@implementation NSImage {
    CGImageRef _cgImageBacking;
    CGSize _size;
    UIImage *_cachedUIImage;
}

+ (BOOL)supportsSecureCoding { return YES; }


- (instancetype)initWithCGImage:(CGImageRef)cgImage size:(CGSize)size {
    if (!cgImage) return nil;
    if ((self = [super init])) {
        _cgImageBacking = CGImageRetain(cgImage);
        _size = size;
        _cachedUIImage = nil;
    }
    return self;
}

- (instancetype)initWithUIImage:(UIImage*)img {
    if (!img) return nil;
    return [self initWithCGImage:img.CGImage size:img.size];
}

- (instancetype)initWithContentsOfFile:(NSString*)p {
    UIImage *img = [UIImage imageWithContentsOfFile:p];
    return [self initWithUIImage:img];
}

- (instancetype)initWithData:(NSData*)d {
    UIImage *img = [UIImage imageWithData:d];
    return [self initWithUIImage:img];
}

+ (NSImage*)imageNamed:(NSString*)n {
    UIImage *img = [UIImage imageNamed:n];
    return img ? [[self alloc] initWithUIImage:img] : nil;
}


- (CGImageRef)CGImage {
    return _cgImageBacking;
}

- (CGSize)size {
    return _size;
}


- (UIImage *)uiImage {
    if (!_cachedUIImage && _cgImageBacking) {
        _cachedUIImage = [UIImage imageWithCGImage:_cgImageBacking];
    }
    return _cachedUIImage;
}


- (NSData*)TIFFRepresentation {
    if (!_cgImageBacking) return nil;
    NSMutableData *data = [NSMutableData data];
    CGImageDestinationRef dest = CGImageDestinationCreateWithData((CFMutableDataRef)data, kUTTypePNG, 1, NULL);
    if (!dest) return nil;
    CGImageDestinationAddImage(dest, _cgImageBacking, nil);
    if (!CGImageDestinationFinalize(dest)) {
        CFRelease(dest);
        return nil;
    }
    CFRelease(dest);
    return data;
}

- (NSData*)PNGRepresentation {
    return [self TIFFRepresentation];
}

- (NSData*)JPEGRepresentationWithCompression:(CGFloat)q {
    if (!_cgImageBacking) return nil;

    NSMutableData *data = [NSMutableData data];
    CGImageDestinationRef dest = CGImageDestinationCreateWithData((CFMutableDataRef)data, kUTTypeJPEG, 1, NULL);
    if (!dest) return nil;
    NSDictionary *props = @{ (id)kCGImageDestinationLossyCompressionQuality : @(q) };
    CGImageDestinationAddImage(dest, _cgImageBacking, (CFDictionaryRef)props);
    if (!CGImageDestinationFinalize(dest)) {
        CFRelease(dest);
        return nil;
    }
    CFRelease(dest);
    return data;
}


- (id)copyWithZone:(NSZone*)z {
    return [[NSImage allocWithZone:z] initWithCGImage:_cgImageBacking size:_size];
}

- (void)encodeWithCoder:(NSCoder*)c {
    NSData *data = [self PNGRepresentation];
    [c encodeObject:data forKey:@"data"];
}

- (instancetype)initWithCoder:(NSCoder*)c {
    NSData *data = [c decodeObjectOfClass:[NSData class] forKey:@"data"];
    UIImage *img = [UIImage imageWithData:data];
    return [self initWithUIImage:img];
}


- (void)dealloc {
    if (_cgImageBacking) CFRelease(_cgImageBacking);
}

@end