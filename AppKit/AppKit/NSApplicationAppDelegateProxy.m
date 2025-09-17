//
//  NSApplicationAppDelegateProxy.m
//  AppKit-iOS
//
//  Created by Stossy11 on 28/08/2025.
//

#include "NSApplicationAppDelegateProxy.h"


@implementation NSApplicationAppDelegateProxy {
    NSBundle *_appBundle;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSString *delegateClassName = [_appBundle objectForInfoDictionaryKey:@"NSAppDelegateClass"];
    if (delegateClassName) {
        id delegate = [[NSClassFromString(delegateClassName) alloc] init];
        [NSApplication sharedApplication].delegate = delegate;
        if ([delegate respondsToSelector:@selector(applicationDidFinishLaunching:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate applicationDidFinishLaunching:[NSNotification notificationWithName:@"NSApplicationDidFinishLaunchingNotification" object:nil]];
            });
        }
    }
    return YES;
}
- (nonnull instancetype)initWithBundle:(nonnull NSBundle *)bundle {
    self.appBundle = bundle;
    return self;
}

@end
