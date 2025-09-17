//
//  NSAlert.m
//  AppKit-iOS
//
//  Created by Stossy11 on 30/08/2025.
//

#import <Foundation/Foundation.h>
#import "NSWindow.h"
#import "NSAlert.h"

@interface NSAlert ()
@property (nonatomic, strong) UIAlertController *alertController;
@property (nonatomic, strong, readwrite) NSMutableArray<NSString *> *buttonTitles;
@end

@implementation NSAlert

- (instancetype)init {
    self = [super init];
    if (self) {
        _messageText = @"";
        _informativeText = @"";
        _alertStyle = NSAlertStyleInformational;
        _buttonTitles = [NSMutableArray array];
    }
    return self;
}

- (void)addButtonWithTitle:(NSString *)title {
    if (title.length > 0) {
        [self.buttonTitles addObject:title];
    }
}

- (UIColor *)colorForAlertStyle {
    switch (self.alertStyle) {
        case NSAlertStyleWarning:
            return [UIColor systemOrangeColor];
        case NSAlertStyleCritical:
            return [UIColor systemRedColor];
        case NSAlertStyleInformational:
        default:
            return [UIColor systemBlueColor];
    }
}

- (NSModalResponse)runModal {
    if (self.buttonTitles.count == 0) {
        [self addButtonWithTitle:@"OK"];
    }
    
    __block NSModalResponse response = NSModalResponseCancel;
    __block BOOL finished = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentAlertWithCompletion:^(NSModalResponse returnCode) {
            response = returnCode;
            finished = YES;
        }];
    });
    
    NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
    while (!finished) {
        @autoreleasepool {
            [runLoop runMode:NSDefaultRunLoopMode
                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
        }
    }
    
    return response;
}

- (void)beginSheetModalForWindow:(NSWindow *)window
                completionHandler:(void(^)(NSModalResponse returnCode))handler {
    if (self.buttonTitles.count == 0) {
        [self addButtonWithTitle:@"OK"];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentAlertWithCompletion:handler forWindow:window];
    });
}

- (void)presentAlertWithCompletion:(void(^)(NSModalResponse returnCode))handler {
    [self presentAlertWithCompletion:handler forWindow:nil];
}

- (void)presentAlertWithCompletion:(void(^)(NSModalResponse returnCode))handler
                         forWindow:(NSWindow * _Nullable)window {
    self.alertController = [UIAlertController alertControllerWithTitle:self.messageText
                                                               message:self.informativeText
                                                        preferredStyle:UIAlertControllerStyleAlert];
    
    for (NSInteger i = 0; i < self.buttonTitles.count; i++) {
        NSString *title = self.buttonTitles[i];
        UIAlertActionStyle style = (i == 0) ? UIAlertActionStyleDefault : UIAlertActionStyleCancel;
        UIAlertAction *action = [UIAlertAction actionWithTitle:title
                                                         style:style
                                                       handler:^(UIAlertAction * _Nonnull action) {
            NSModalResponse code = NSModalResponseOK + i;
            if (handler) handler(code);
        }];
        [self.alertController addAction:action];
        
        if (i == 0) {
            self.alertController.preferredAction = action;
        }
    }
    
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *presentingVC = keyWindow.rootViewController ?: [UIApplication sharedApplication].keyWindow.rootViewController;
    [presentingVC presentViewController:self.alertController animated:YES completion:nil];
}

@end
