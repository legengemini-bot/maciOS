//
//  NSAlert.h
//  AppKit-iOS
//
//  Created by Stossy11 on 30/08/2025.
//

#import <Foundation/Foundation.h>

@class NSButton;

typedef NSInteger NSModalResponse;

static const NSModalResponse NSModalResponseNone      = 0;
static const NSModalResponse NSModalResponseOK        = 1;
static const NSModalResponse NSModalResponseCancel    = 0;
static const NSModalResponse NSModalResponseAbort     = 2;
static const NSModalResponse NSModalResponseRetry     = 3;
static const NSModalResponse NSModalResponseIgnore    = 4;
static const NSModalResponse NSModalResponseYes       = 6;
static const NSModalResponse NSModalResponseNo        = 7;
static const NSModalResponse NSModalResponseStop      = 8;
static const NSModalResponse NSModalResponseContinue  = 9;

static const NSModalResponse NSModalResponseFirstButtonReturn  = NSModalResponseOK;
static const NSModalResponse NSModalResponseSecondButtonReturn = NSModalResponseCancel;
static const NSModalResponse NSModalResponseThirdButtonReturn  = 2;

typedef NS_ENUM(NSInteger, NSAlertStyle) {
    NSAlertStyleWarning,
    NSAlertStyleInformational,
    NSAlertStyleCritical
};

@interface NSAlert : NSObject

@property (nonatomic, copy) NSString *messageText;
@property (nonatomic, copy) NSString *informativeText;
@property (nonatomic, assign) NSAlertStyle alertStyle;
@property (nonatomic, strong, readonly) NSMutableArray<NSButton*> *buttons;

- (NSModalResponse)runModal;

- (void)beginSheetModalForWindow:(NSWindow *)window
                completionHandler:(void(^)(NSModalResponse returnCode))handler;

- (void)addButtonWithTitle:(NSString *)title;

@end

