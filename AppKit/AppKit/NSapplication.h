//
//  NSapplication.h
//  AppKit-iOS
//
//  Created by Stossy11 on 30/08/2025.
//

#import <Foundation/Foundation.h>
#import "NSResponder.h"

@class NSApplication;
@class NSWindow;
@class NSNotification;
@class NSResponder;

typedef NSInteger NSModalResponse;

NS_ASSUME_NONNULL_BEGIN

int NSApplicationMain(int argc, const char * argv[]);

@protocol NSApplicationDelegate <NSObject>
@optional
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (void)applicationWillTerminate:(NSNotification *)notification;
@end

@interface NSApplication : NSResponder

@property (nonatomic, weak, nullable) id<NSApplicationDelegate> delegate;
@property (nonatomic, strong, readonly) NSMutableArray<NSWindow *> *windows;
@property (nonatomic, assign, readonly) BOOL isRunning;

+ (instancetype)sharedApplication;
+ (void)initialize;

- (instancetype)initForThread:(NSThread *)thread;

- (void)run;
- (void)terminate:(nullable id)sender;
- (void)hide:(nullable id)sender;
- (void)unhide:(nullable id)sender;

- (void)addWindow:(NSWindow *)window;
- (void)removeWindow:(NSWindow *)window;

- (nullable NSWindow *)keyWindow;
- (nullable NSWindow *)mainWindow;

- (NSModalResponse)runModalForWindow:(NSWindow *)window;
- (void)stopModal;
- (void)abortModal;

@end

NS_ASSUME_NONNULL_END
