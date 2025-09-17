//
//  NSApplication.m
//  AppKit-iOS
//
//  Created by Stossy11 on 30/08/2025.
//

#import <Foundation/Foundation.h>
#import "NSapplication.h"
#import "NSAlert.h"
#import "NSWindow.h"

@implementation NSApplication {
    NSThread *_owningThread;
}

static NSMutableDictionary<NSValue*, NSApplication*> *_threadApplications = nil;
static dispatch_once_t _threadApplicationsOnce;

+ (void)initialize {
    if (self == [NSApplication class]) {
        dispatch_once(&_threadApplicationsOnce, ^{
            _threadApplications = [[NSMutableDictionary alloc] init];
        });
    }
}

+ (instancetype)sharedApplication {
    NSThread *currentThread = [NSThread currentThread];
    NSValue *threadKey = [NSValue valueWithPointer:(__bridge const void *)currentThread];
    
    @synchronized(_threadApplications) {
        NSApplication *app = _threadApplications[threadKey];
        if (!app) {
            NSString *threadName = currentThread.name ?: [NSString stringWithFormat:@"Thread-%p", currentThread];
            app = [[NSApplication alloc] init];
            app->_owningThread = currentThread;
            _threadApplications[threadKey] = app;
            
            [[NSNotificationCenter defaultCenter] addObserverForName:NSThreadWillExitNotification
                                                              object:currentThread
                                                               queue:nil
                                                          usingBlock:^(NSNotification *note) {
                @synchronized(_threadApplications) {
                    [app terminate:nil];
                    [_threadApplications removeObjectForKey:threadKey];
                }
            }];
            
            NSString *logThreadName = currentThread.name ?: [NSString stringWithFormat:@"Thread-%p", currentThread];
        }
        return app;
    }
}

- (instancetype)initForThread:(NSThread*)thread {
    self = [super init];
    if (self) {
        _owningThread = thread;
        _windows = [NSMutableArray array];
        _isRunning = NO;
        NSString *threadName = thread.name ?: [NSString stringWithFormat:@"Thread-%p", thread];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _windows = [NSMutableArray array];
        _isRunning = NO;
        if (!_owningThread) {
            _owningThread = [NSThread currentThread];
        }
    }
    return self;
}

- (void)run {
    NSString *threadName = _owningThread.name ?: [NSString stringWithFormat:@"Thread-%p", _owningThread];
    _isRunning = YES;
    
    if ([self.delegate respondsToSelector:@selector(applicationDidFinishLaunching:)]) {
        NSNotification *notification = [NSNotification notificationWithName:@"NSApplicationDidFinishLaunching"
                                                                      object:self
                                                                    userInfo:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate applicationDidFinishLaunching:notification];
        });
    }
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    while (_isRunning && !_owningThread.isCancelled) {
        @autoreleasepool {
            NSDate *nextDate = [NSDate dateWithTimeIntervalSinceNow:0.05];
            [runLoop runMode:NSDefaultRunLoopMode beforeDate:nextDate];
            
            if (_owningThread.isCancelled) {
                break;
            }
        }
    }
}

- (void)terminate:(id)sender {
    _isRunning = NO;
    
    if ([self.delegate respondsToSelector:@selector(applicationWillTerminate:)]) {
        NSNotification *notification = [NSNotification notificationWithName:@"NSApplicationWillTerminate"
                                                                      object:self
                                                                    userInfo:nil];
        [self.delegate applicationWillTerminate:notification];
    }
    
    NSArray *windowsCopy = [_windows copy];
    for (NSWindow *window in windowsCopy) {
        [window close];
    }
    
    NSString *threadName = _owningThread.name ?: [NSString stringWithFormat:@"Thread-%p", _owningThread];
}

- (void)addWindow:(NSWindow*)window {
    [self.windows addObject:window];
    NSString *threadName = _owningThread.name ?: [NSString stringWithFormat:@"Thread-%p", _owningThread];
}

- (void)removeWindow:(NSWindow*)window {
    [self.windows removeObject:window];
    NSString *threadName = _owningThread.name ?: [NSString stringWithFormat:@"Thread-%p", _owningThread];
}

- (NSWindow*)keyWindow {
    for (NSWindow *window in self.windows) {
        if (window.visible) {
            return window;
        }
    }
    return nil;
}

- (NSWindow*)mainWindow {
    return [self keyWindow];
}

- (void)hide:(id)sender {
    for (NSWindow *window in self.windows) {
        window.contentView.hidden = YES;
    }
}

- (void)unhide:(id)sender {
    for (NSWindow *window in self.windows) {
        window.contentView.hidden = NO;
    }
}

- (NSModalResponse)runModalForWindow:(NSWindow*)window {
    [window makeKeyAndVisible];
    return NSModalResponseOK;
}

- (void)stopModal {
}

- (void)abortModal {
}

@end

// for when subproesses are implemented
int NSApplicationMain(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        NSThread *currentThread = [NSThread currentThread];
        NSString *threadName = currentThread.name ?: [NSString stringWithFormat:@"Thread-%p", currentThread];
        
        char *envPath = getenv("maciOS_APP_BUNDLE_PATH");
        if (!envPath) {
            return -1;
        }
        
        NSString *bundlePath = [NSString stringWithUTF8String:envPath];
        NSBundle *dynamicBundle = [NSBundle bundleWithPath:bundlePath];
        if (!dynamicBundle) {
            return -1;
        }
        
        NSError *loadError = nil;
        if (![dynamicBundle loadAndReturnError:&loadError]) {
            return -1;
        }
        
        NSString *delegateClassName = [dynamicBundle objectForInfoDictionaryKey:@"NSPrincipalClass"];
        if (!delegateClassName) {
            delegateClassName = [dynamicBundle objectForInfoDictionaryKey:@"NSAppDelegateClass"];
        }
        
        id delegateInstance = nil;
        if (delegateClassName) {
            Class delegateClass = NSClassFromString(delegateClassName);
            if (delegateClass) {
                delegateInstance = [[delegateClass alloc] init];
            }
        }
        
        if (delegateInstance) {
            app.delegate = delegateInstance;
        }
        
        [app run];
    }
    return 0;
}
