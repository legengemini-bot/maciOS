//
//  NSApplicationAppDelegateProxy.m
//  AppKit-iOS
//
//  Created by Stossy11 on 28/08/2025.
//

#include "NSApplication.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface NSApplicationAppDelegateProxy : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong, nullable) UIWindow *window;

@property (nonatomic, strong, nullable) NSBundle *appBundle;


- (instancetype)initWithBundle:(NSBundle *)bundle;

@end

NS_ASSUME_NONNULL_END
