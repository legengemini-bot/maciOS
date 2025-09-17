//
//  NSImage.h
//  AppKit
//
//  Created by Stossy11 on 25/08/2025.
//


#import <UIKit/UIKit.h>

@interface NSImage : NSObject <NSSecureCoding, NSCopying>

@property (nonatomic, readonly) UIImage *uiImage;
@property (nonatomic, readonly) CGSize size;

@property (nonatomic, readonly) CGImageRef CGImage;

- (instancetype)initWithUIImage:(UIImage *)img;
- (instancetype)initWithCGImage:(CGImageRef)cgImage size:(CGSize)size;
- (instancetype)initWithContentsOfFile:(NSString *)path;
- (instancetype)initWithData:(NSData *)data;

+ (NSImage *)imageNamed:(NSString *)name;


- (NSData *)TIFFRepresentation;
- (NSData *)PNGRepresentation;
- (NSData *)JPEGRepresentationWithCompression:(CGFloat)quality;

@end
