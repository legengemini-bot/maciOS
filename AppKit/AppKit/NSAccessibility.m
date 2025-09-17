//
//  NSAccessibility.m
//  AppKit-iOS
//
//  Created by Stossy11 on 28/08/2025.
//

#import "NSAccessibility.h"
#import <UIKit/UIKit.h>

NSString * const NSAccessibilityFocusedUIElementChangedNotification = @"NSAccessibilityFocusedUIElementChangedNotification";
NSString * const NSAccessibilityValueChangedNotification            = @"NSAccessibilityValueChangedNotification";
NSString * const NSAccessibilityCreatedNotification                 = @"NSAccessibilityCreatedNotification";
NSString * const NSAccessibilityUIElementDestroyedNotification      = @"NSAccessibilityUIElementDestroyedNotification";
NSString * const NSAccessibilityTitleChangedNotification            = @"NSAccessibilityTitleChangedNotification";
NSString * const NSAccessibilityWindowCreatedNotification           = @"NSAccessibilityWindowCreatedNotification";
NSString * const NSAccessibilityLayoutChangedNotification           = @"NSAccessibilityLayoutChangedNotification";
NSString * const NSAccessibilityAnnouncementRequestedNotification   = @"NSAccessibilityAnnouncementRequestedNotification";

NSString * const NSAccessibilityButtonRole       = @"NSAccessibilityButtonRole";
NSString * const NSAccessibilityCheckBoxRole     = @"NSAccessibilityCheckBoxRole";
NSString * const NSAccessibilityRadioButtonRole  = @"NSAccessibilityRadioButtonRole";
NSString * const NSAccessibilityTextFieldRole    = @"NSAccessibilityTextFieldRole";
NSString * const NSAccessibilityStaticTextRole   = @"NSAccessibilityStaticTextRole";
NSString * const NSAccessibilityWindowRole       = @"NSAccessibilityWindowRole";
NSString * const NSAccessibilityImageRole        = @"NSAccessibilityImageRole";
NSString * const NSAccessibilityGroupRole        = @"NSAccessibilityGroupRole";

NSString * const NSAccessibilityRoleAttribute       = @"NSAccessibilityRoleAttribute";
NSString * const NSAccessibilitySubroleAttribute    = @"NSAccessibilitySubroleAttribute";
NSString * const NSAccessibilityTitleAttribute      = @"NSAccessibilityTitleAttribute";
NSString * const NSAccessibilityValueAttribute      = @"NSAccessibilityValueAttribute";
NSString * const NSAccessibilityEnabledAttribute    = @"NSAccessibilityEnabledAttribute";
NSString * const NSAccessibilityFocusedAttribute    = @"NSAccessibilityFocusedAttribute";
NSString * const NSAccessibilityParentAttribute     = @"NSAccessibilityParentAttribute";
NSString * const NSAccessibilityChildrenAttribute   = @"NSAccessibilityChildrenAttribute";
NSString * const NSAccessibilityWindowAttribute     = @"NSAccessibilityWindowAttribute";
NSString * const NSAccessibilityFrameAttribute      = @"NSAccessibilityFrameAttribute";

NSString * const NSAccessibilityPressAction        = @"NSAccessibilityPressAction";
NSString * const NSAccessibilityIncrementAction    = @"NSAccessibilityIncrementAction";
NSString * const NSAccessibilityDecrementAction    = @"NSAccessibilityDecrementAction";
NSString * const NSAccessibilityConfirmAction      = @"NSAccessibilityConfirmAction";
NSString * const NSAccessibilityCancelAction       = @"NSAccessibilityCancelAction";

void NSAccessibilityPostNotification(id element, NSString *notification) {
    if (!element || !notification) return;
    NSLog(@"[Accessibility] Notification: %@ for element: %@", notification, element);

    if ([notification isEqualToString:NSAccessibilityValueChangedNotification]) {
        NSString *announcement = [NSString stringWithFormat:@"Value changed for %@", element];
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, announcement);
    }
    else if ([notification isEqualToString:NSAccessibilityFocusedUIElementChangedNotification]) {
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, element);
    }
    else if ([notification isEqualToString:NSAccessibilityLayoutChangedNotification]) {
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, element);
    }
    else if ([notification isEqualToString:NSAccessibilityAnnouncementRequestedNotification]) {
        if ([element isKindOfClass:[NSString class]]) {
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, element);
        }
    }
}
