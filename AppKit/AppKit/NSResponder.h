//
//  NSResponder.h
//  AppKit-iOS
//
//  Created by Stossy11 on 30/08/2025.
//

#import <Foundation/Foundation.h>

@class NSEvent;

@interface NSResponder : NSObject

- (BOOL)acceptsFirstResponder;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

- (void)keyDown:(NSEvent*)event;
- (void)keyUp:(NSEvent*)event;
- (void)mouseDown:(NSEvent*)event;
- (void)mouseUp:(NSEvent*)event;
- (void)mouseDragged:(NSEvent*)event;

@end
