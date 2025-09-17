//
//  NSResponder.m
//  AppKit-iOS
//
//  Created by Stossy11 on 30/08/2025.
//

#import "NSResponder.h"

@implementation NSResponder

- (BOOL)acceptsFirstResponder {
    return NO; 
}

- (BOOL)becomeFirstResponder {
    return NO; 
}
- (BOOL)resignFirstResponder {
    return YES; 
}
- (void)keyDown:(NSEvent*)event {
}

- (void)keyUp:(NSEvent*)event {
}

- (void)mouseDown:(NSEvent*)event {
}

- (void)mouseUp:(NSEvent*)event {
}

- (void)mouseDragged:(NSEvent*)event {
}

@end
